import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/game_session.dart';

class GameRepository {
  final SupabaseClient _supabase;
  GameRepository(this._supabase);

  final _uuid = const Uuid();

  // =========================================================
  // 🔥 MAIN ENTRY — CALL THIS WHEN GAME COMPLETES
  // =========================================================
  Future<void> recordCompletedGame({
    required String gameId,
    required int score,
    required int durationSeconds,
    required int attempts,
    String difficulty = 'easy',
    int maxScore = 1000,
  }) async {
    final patientId = _supabase.auth.currentUser?.id;
    if (patientId == null) throw Exception('User is not authenticated.');

    await _insertSession(
      patientId: patientId,
      gameId: gameId,
      score: score,
      durationSeconds: durationSeconds,
      attempts: attempts,
      difficulty: difficulty,
      maxScore: maxScore,
    );

    await _upsertAnalytics(
      patientId: patientId,
      gameType: gameId,
      score: score,
      durationSeconds: durationSeconds,
    );
  }

  // =========================================================
  // INSERT SESSION (matches your NEW schema)
  // =========================================================
  Future<void> _insertSession({
    required String patientId,
    required String gameId,
    required int score,
    required int durationSeconds,
    required int attempts,
    required String difficulty,
    required int maxScore,
  }) async {
    final now = DateTime.now().toIso8601String();

    try {
      final res = await _supabase.from('game_sessions').insert({
        'id': _uuid.v4(),
        'patient_id': patientId,
        'game_id': gameId,
        'started_at': now,
        'completed_at': now,
        'score': score,
        'max_score': maxScore,
        'attempts': attempts,
        'time_taken_seconds': durationSeconds,
        'difficulty_level': difficulty,
        'is_completed': true,
        'created_at': now,
        'played_at': now,
        'duration_seconds': durationSeconds,
        'accuracy': (score / maxScore).clamp(0, 1),
      }).select();

      if (kDebugMode) {
        print('✅ game_sessions inserted: $res');
      }
    } catch (e, st) {
      if (kDebugMode) {
        print('❌ INSERT FAILED: $e');
        print(st);
      }
      throw Exception('INSERT FAILED: $e');
    }
  }

  // =========================================================
  // UPSERT DAILY ANALYTICS
  // =========================================================
  Future<void> _upsertAnalytics({
    required String patientId,
    required String gameType,
    required int score,
    required int durationSeconds,
  }) async {
    final today = DateTime.now().toIso8601String().split('T').first;

    final existing = await _supabase
        .from('game_analytics_daily')
        .select()
        .eq('patient_id', patientId)
        .eq('game_type', gameType)
        .eq('analytics_date', today)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('game_analytics_daily').insert({
        'id': _uuid.v4(),
        'patient_id': patientId,
        'game_type': gameType,
        'session_count': 1,
        'avg_score': score.toDouble(),
        'best_score': score,
        'total_duration_seconds': durationSeconds,
        'analytics_date': today,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      final int sessionCount = existing['session_count'];
      final int totalDuration = existing['total_duration_seconds'];
      final double avgScore = existing['avg_score'];
      final int bestScore = existing['best_score'];

      final newCount = sessionCount + 1;
      final newAvg = ((avgScore * sessionCount) + score) / newCount;

      await _supabase.from('game_analytics_daily').update({
        'session_count': newCount,
        'avg_score': newAvg,
        'best_score': score > bestScore ? score : bestScore,
        'total_duration_seconds': totalDuration + durationSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existing['id']);
    }
  }

  // =========================================================
  // PROVIDER COMPATIBILITY METHODS
  // =========================================================

  Future<List<GameSession>> fetchRemoteSessions(String patientId) async {
    final response = await _supabase
        .from('game_sessions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      final map = Map<String, dynamic>.from(row);
      // Ensure game_type is populated from game_id if missing
      if (map['game_type'] == null && map['game_id'] != null) {
        map['game_type'] = map['game_id'];
      }
      return GameSession.fromJson(map);
    }).toList();
  }

  Future<Map<String, dynamic>> getGameStats(String patientId) async {
    final response = await _supabase
        .from('game_analytics_daily')
        .select()
        .eq('patient_id', patientId);

    int totalGames = 0;
    int totalDuration = 0;

    for (var row in response) {
      totalGames += (row['session_count'] as num?)?.toInt() ?? 0;
      totalDuration += (row['total_duration_seconds'] as num?)?.toInt() ?? 0;
    }

    return {
      'total_games': totalGames,
      'total_duration': totalDuration,
      'analytics': response,
    };
  }

  Future<void> uploadSession(GameSession session) async {
    final payload = session.toJson();
    if (!payload.containsKey('game_id') || payload['game_id'] == null) {
      payload['game_id'] = session.gameType;
    }
    payload['played_at'] ??= session.completedAt.toIso8601String();

    // Add default values for fields required by the new database schema
    payload['max_score'] ??= 1000;
    payload['accuracy'] ??=
        ((payload['score'] as num? ?? 0) / 1000).clamp(0, 1);
    payload['is_completed'] ??= true;
    payload['difficulty_level'] ??= 'easy';
    payload['attempts'] ??= 1;

    await _supabase.from('game_sessions').insert(payload);
  }

  Future<void> deleteRemoteSession(String sessionId) async {
    await _supabase.from('game_sessions').delete().eq('id', sessionId);
  }
}
