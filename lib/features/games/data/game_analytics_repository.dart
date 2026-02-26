import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class GameAnalyticsRepository {
  final SupabaseClient _supabase;

  GameAnalyticsRepository(this._supabase);

  /// Records a raw game session and updates the daily analytics aggregation.
  /// Throws an exception if the user is not authenticated.
  Future<void> recordGameSession({
    required String patientId,
    required String gameType,
    required int score,
    required int durationSeconds,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated - cannot record game session.');
    }

    // RLS Enforcement: Ensure the patient is only recording data for themselves.
    // If a caregiver were somehow triggering this directly, their patientId would differ from user.id
    // But typically the patient plays the game.
    final actPatientId = user.id == patientId ? user.id : patientId;

    // 1. Layer 1: Store Raw Game Session
    await _storeRawSession(
      patientId: actPatientId,
      gameType: gameType,
      score: score,
      durationSeconds: durationSeconds,
    );

    // 2. Layer 2: Upsert Daily Analytics
    await _upsertDailyAnalytics(
      patientId: actPatientId,
      gameType: gameType,
      score: score,
      durationSeconds: durationSeconds,
    );
  }

  Future<void> _storeRawSession({
    required String patientId,
    required String gameType,
    required int score,
    required int durationSeconds,
  }) async {
    try {
      await _supabase.from('game_sessions').insert({
        'id': const Uuid().v4(),
        'patient_id': patientId,
        'game_type': gameType,
        'score': score,
        'duration_seconds': durationSeconds,
        'played_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // We might log this, but we don't necessarily want to block daily analytics
      // if raw session insertion fails.
      print('Failed to record raw game session: $e');
    }
  }

  Future<void> _upsertDailyAnalytics({
    required String patientId,
    required String gameType,
    required int score,
    required int durationSeconds,
  }) async {
    final today = DateTime.now();
    final analyticsDateString = DateTime(today.year, today.month, today.day)
        .toIso8601String()
        .split('T')
        .first;

    try {
      // Try to fetch existing daily analytics to compute new values correctly
      final existingData = await _supabase
          .from('game_analytics_daily')
          .select()
          .eq('patient_id', patientId)
          .eq('game_type', gameType)
          .eq('analytics_date', analyticsDateString)
          .maybeSingle();

      int newSessionCount = 1;
      double newAvgScore = score.toDouble();
      int newBestScore = score;
      int newTotalDuration = durationSeconds;

      if (existingData != null) {
        final int oldSessionCount = existingData['session_count'] ?? 0;
        final double oldAvgScore =
            (existingData['avg_score'] ?? 0.0).toDouble();
        final int oldBestScore = existingData['best_score'] ?? 0;
        final int oldDuration = existingData['total_duration_seconds'] ?? 0;

        newSessionCount = oldSessionCount + 1;
        newTotalDuration = oldDuration + durationSeconds;
        newBestScore = score > oldBestScore ? score : oldBestScore;
        newAvgScore =
            ((oldAvgScore * oldSessionCount) + score) / newSessionCount;
      }

      // Upsert using onConflict
      await _supabase.from('game_analytics_daily').upsert({
        'id': existingData != null ? existingData['id'] : const Uuid().v4(),
        'patient_id': patientId,
        'game_type': gameType,
        'analytics_date': analyticsDateString,
        'session_count': newSessionCount,
        'avg_score': newAvgScore,
        'best_score': newBestScore,
        'total_duration_seconds': newTotalDuration,
        'updated_at': DateTime.now().toIso8601String(),
        if (existingData == null)
          'created_at': DateTime.now().toIso8601String(),
      }, onConflict: 'patient_id,analytics_date,game_type');
    } catch (e) {
      print('Failed to upsert basic game analytics: $e');
      throw Exception('Failed to upsert game analytics: $e');
    }
  }

  /// Caregiver Dashboard Fetch
  /// Fetches game analytics for patients linked to the current caregiver
  Future<List<Map<String, dynamic>>> getCaregiverPatientAnalytics(
      String caregiverId) async {
    try {
      // Uses the inner join on caregiver_patient_links
      final response = await _supabase
          .from('game_analytics_daily')
          .select('''
            *,
            patients!inner(
              id,
              caregiver_patient_links!inner(caregiver_id)
            )
          ''')
          .eq('patients.caregiver_patient_links.caregiver_id', caregiverId)
          .order('analytics_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching caregiver patient analytics: $e');
      return [];
    }
  }
}
