import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/service_providers.dart';
import '../models/game_analytics_summary.dart';

final gameAnalyticsRepositoryProvider =
    Provider<GameAnalyticsRepository>((ref) {
  return GameAnalyticsRepository(ref.watch(supabaseClientProvider));
});

class GameAnalyticsRepository {
  final SupabaseClient _supabase;

  GameAnalyticsRepository(this._supabase);

  /// Fetch weekly analytics from the aggregated `game_analytics_daily` table
  /// Limits to the last 7 days. Returns a lightweight summary model.
  Future<GameAnalyticsSummary> getWeeklyAnalytics(String patientId) async {
    try {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      final dateBoundary = sevenDaysAgo.toIso8601String().split('T')[0];

      // Use exactly minimal columns requested
      final response = await _supabase
          .from('game_analytics_daily')
          .select(
              'analytics_date, session_count, total_duration_seconds, avg_score, best_score')
          .eq('patient_id', patientId)
          .gte('analytics_date', dateBoundary)
          .order('analytics_date', ascending: false)
          .timeout(const Duration(seconds: 5)); // Guard against hangs

      if (response.isEmpty) {
        return const GameAnalyticsSummary(hasData: false);
      }

      int totalGames = 0;
      int totalPlayTime = 0;
      double totalScoreSum = 0.0;
      DateTime? lastPlayedAt;

      for (int i = 0; i < response.length; i++) {
        final row = response[i];
        final dailyGames = (row['session_count'] as num?)?.toInt() ?? 0;
        final dailyDuration =
            (row['total_duration_seconds'] as num?)?.toInt() ?? 0;
        final dailyAvgScore = (row['avg_score'] as num?)?.toDouble() ?? 0.0;

        if (dailyGames == 0) continue;

        if (lastPlayedAt == null) {
          // Because records are ordered date desc, the first loop with games > 0 is recent
          try {
            lastPlayedAt = DateTime.parse(row['analytics_date'].toString());
          } catch (_) {}
        }

        totalGames += dailyGames;
        totalPlayTime += dailyDuration;
        totalScoreSum += (dailyAvgScore * dailyGames);
      }

      final double avgScoreThisWeek =
          totalGames > 0 ? totalScoreSum / totalGames : 0.0;
      final double avgAccuracyThisWeek = 0.0; // Dropped from new master schema

      return GameAnalyticsSummary(
        gamesPlayedThisWeek: totalGames,
        totalPlayTimeThisWeek: totalPlayTime,
        avgScoreThisWeek: avgScoreThisWeek,
        avgAccuracyThisWeek: avgAccuracyThisWeek,
        lastPlayedAt: lastPlayedAt,
        hasData: totalGames > 0,
      );
    } catch (e, st) {
      if (kDebugMode) {
        print('[GameAnalyticsRepo] Error fetching analytics: $e');
        print(st);
      }
      // Never crash on empty/error, always return a safe empty model
      return const GameAnalyticsSummary(hasData: false);
    }
  }
}
