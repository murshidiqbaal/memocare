import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/service_providers.dart';

final gameAnalyticsServiceProvider = Provider<GameAnalyticsService>((ref) {
  return GameAnalyticsService(ref.watch(supabaseClientProvider));
});

class GameAnalyticsService {
  final SupabaseClient _supabase;
  static const _offlineQueueKey = 'offline_analytics_queue';

  GameAnalyticsService(this._supabase) {
    _syncOfflineQueue();
  }

  Future<void> recordGameSession({
    required String patientId,
    required String gameType,
    required int score,
    required int durationSeconds,
  }) async {
    final today = DateTime.now().toIso8601String().split('T')[0];

    final sessionData = {
      'patient_id': patientId,
      'game_type': gameType,
      'score': score,
      'duration_seconds': durationSeconds,
      'analytics_date': today,
    };

    try {
      await _processUpsert(sessionData);
      await _syncOfflineQueue();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to upload session. Queueing offline. Error: $e');
      }
      await _queueOfflineSession(sessionData);
    }
  }

  Future<void> _processUpsert(Map<String, dynamic> sessionData) async {
    final patientId = sessionData['patient_id'];
    final gameType = sessionData['game_type'];
    final today = sessionData['analytics_date'];
    final score = sessionData['score'] as int;
    final durationSeconds = sessionData['duration_seconds'] as int;

    final existingRecord = await _supabase
        .from('game_analytics_daily')
        .select()
        .eq('patient_id', patientId)
        .eq('game_type', gameType)
        .eq('analytics_date', today)
        .maybeSingle();

    int newSessionCount = 1;
    double newAvgScore = score.toDouble();
    int newBestScore = score;
    int newTotalDuration = durationSeconds;

    if (existingRecord != null) {
      final int oldSessions = existingRecord['session_count'] as int? ?? 0;
      final double oldAvg =
          (existingRecord['avg_score'] as num?)?.toDouble() ?? 0.0;
      final int oldBest = existingRecord['best_score'] as int? ?? 0;
      final int oldDuration =
          existingRecord['total_duration_seconds'] as int? ?? 0;

      newSessionCount = oldSessions + 1;
      newAvgScore = ((oldAvg * oldSessions) + score) / newSessionCount;
      newBestScore = score > oldBest ? score : oldBest;
      newTotalDuration = oldDuration + durationSeconds;
    }

    await _supabase.from('game_analytics_daily').upsert({
      'patient_id': patientId,
      'game_type': gameType,
      'analytics_date': today,
      'session_count': newSessionCount,
      'avg_score': newAvgScore,
      'best_score': newBestScore,
      'total_duration_seconds': newTotalDuration,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'patient_id, game_type, analytics_date');
  }

  Future<void> _queueOfflineSession(Map<String, dynamic> sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> queue = prefs.getStringList(_offlineQueueKey) ?? [];
      queue.add(jsonEncode(sessionData));
      await prefs.setStringList(_offlineQueueKey, queue);
    } catch (e) {
      if (kDebugMode) print('Failed to write to SharedPreferences: $e');
    }
  }

  Future<void> _syncOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? queue = prefs.getStringList(_offlineQueueKey);

      if (queue == null || queue.isEmpty) return;

      final List<String> remainingQueue = [];
      for (final encoded in queue) {
        try {
          final sessionData = jsonDecode(encoded) as Map<String, dynamic>;
          await _processUpsert(sessionData);
        } catch (e) {
          remainingQueue.add(encoded);
        }
      }

      if (remainingQueue.isEmpty) {
        await prefs.remove(_offlineQueueKey);
      } else {
        await prefs.setStringList(_offlineQueueKey, remainingQueue);
      }
    } catch (e) {
      if (kDebugMode) print('Offline sync failed: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> streamCaregiverAnalytics(
      String patientId) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final dateBoundary = sevenDaysAgo.toIso8601String().split('T')[0];

    return _supabase
        .from('game_analytics_daily')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('analytics_date', ascending: true)
        .map((data) => data
            .where((row) =>
                (row['analytics_date'] as String).compareTo(dateBoundary) >= 0)
            .toList());
  }
}

// ── Riverpod Providers ──

final caregiverAnalyticsProvider = StreamProvider.family
    .autoDispose<List<Map<String, dynamic>>, String>((ref, patientId) {
  if (patientId.isEmpty) return Stream.value([]);
  final service = ref.watch(gameAnalyticsServiceProvider);
  return service.streamCaregiverAnalytics(patientId);
});
