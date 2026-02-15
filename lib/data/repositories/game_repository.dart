import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/game_session.dart';

class GameRepository {
  final SupabaseClient _supabase;
  late Box<GameSession> _box;
  bool _isInit = false;

  GameRepository(this._supabase);

  Future<void> init() async {
    if (_isInit) return;
    _box = await Hive.openBox<GameSession>('game_sessions');
    _isInit = true;
  }

  // ===== Local Operations =====

  /// Get all game sessions for a patient from local storage
  Future<List<GameSession>> getLocalSessions(String patientId) async {
    await init();
    return _box.values
        .where((session) => session.patientId == patientId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  /// Save a new game session locally
  Future<void> saveLocalSession(GameSession session) async {
    await init();
    await _box.put(session.id, session);
  }

  /// Delete a local session
  Future<void> deleteLocalSession(String sessionId) async {
    await init();
    await _box.delete(sessionId);
  }

  // ===== Remote Operations =====

  /// Fetch game sessions from Supabase
  Future<List<GameSession>> fetchRemoteSessions(String patientId) async {
    try {
      final response = await _supabase
          .from('game_sessions')
          .select()
          .eq('patient_id', patientId)
          .order('completed_at', ascending: false);

      return (response as List)
          .map((json) => GameSession.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch game sessions: $e');
    }
  }

  /// Upload a single session to Supabase
  Future<void> uploadSession(GameSession session) async {
    try {
      await _supabase.from('game_sessions').insert(session.toJson());
    } catch (e) {
      throw Exception('Failed to upload session: $e');
    }
  }

  /// Delete a session from Supabase
  Future<void> deleteRemoteSession(String sessionId) async {
    try {
      await _supabase.from('game_sessions').delete().eq('id', sessionId);
    } catch (e) {
      throw Exception('Failed to delete session: $e');
    }
  }

  // ===== Sync Operations =====

  /// Sync local sessions to remote (upload unsynced)
  Future<void> syncToRemote(String patientId) async {
    await init();
    final unsyncedSessions = _box.values
        .where((s) => s.patientId == patientId && !s.isSynced)
        .toList();

    for (final session in unsyncedSessions) {
      try {
        await uploadSession(session);
        // Mark as synced
        final synced = session.copyWith(isSynced: true);
        await _box.put(session.id, synced);
      } catch (e) {
        // Continue with other sessions even if one fails
        print('Failed to sync session ${session.id}: $e');
      }
    }
  }

  /// Sync remote sessions to local (download and merge)
  Future<void> syncFromRemote(String patientId) async {
    await init();
    try {
      final remoteSessions = await fetchRemoteSessions(patientId);

      for (final session in remoteSessions) {
        // Only add if not already in local storage
        if (!_box.containsKey(session.id)) {
          await _box.put(session.id, session);
        }
      }
    } catch (e) {
      print('Failed to sync from remote: $e');
    }
  }

  /// Full bidirectional sync
  Future<void> fullSync(String patientId) async {
    await syncToRemote(patientId);
    await syncFromRemote(patientId);
  }

  // ===== Analytics =====

  /// Get game statistics for a patient
  Future<Map<String, dynamic>> getGameStats(String patientId) async {
    await init();
    final sessions = await getLocalSessions(patientId);

    if (sessions.isEmpty) {
      return {
        'totalGames': 0,
        'averageScore': 0.0,
        'bestScore': 0,
        'totalPlayTime': 0,
        'gamesByType': <String, int>{},
      };
    }

    final totalGames = sessions.length;
    final averageScore =
        sessions.map((s) => s.score).reduce((a, b) => a + b) / totalGames;
    final bestScore =
        sessions.map((s) => s.score).reduce((a, b) => a > b ? a : b);
    final totalPlayTime =
        sessions.map((s) => s.durationSeconds).reduce((a, b) => a + b);

    final gamesByType = <String, int>{};
    for (final session in sessions) {
      gamesByType[session.gameType] = (gamesByType[session.gameType] ?? 0) + 1;
    }

    return {
      'totalGames': totalGames,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'totalPlayTime': totalPlayTime,
      'gamesByType': gamesByType,
      'recentSessions': sessions.take(10).toList(),
    };
  }

  /// Get sessions within a date range
  Future<List<GameSession>> getSessionsInRange(
    String patientId,
    DateTime start,
    DateTime end,
  ) async {
    await init();
    return _box.values
        .where((s) =>
            s.patientId == patientId &&
            s.completedAt.isAfter(start) &&
            s.completedAt.isBefore(end))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }
}
