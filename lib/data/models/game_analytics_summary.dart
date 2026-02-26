/// Summary of a patient's game analytics over a specific period (e.g. 7 days)
class GameAnalyticsSummary {
  final int gamesPlayedThisWeek;
  final int totalPlayTimeThisWeek; // in seconds
  final double avgScoreThisWeek;
  final double avgAccuracyThisWeek;
  final DateTime? lastPlayedAt;
  final bool hasData;

  const GameAnalyticsSummary({
    this.gamesPlayedThisWeek = 0,
    this.totalPlayTimeThisWeek = 0,
    this.avgScoreThisWeek = 0.0,
    this.avgAccuracyThisWeek = 0.0,
    this.lastPlayedAt,
    this.hasData = false,
  });

  /// Get formatted play time (e.g., "2h 15m" or "45m")
  String get formattedPlayTime {
    if (totalPlayTimeThisWeek < 60) return '${totalPlayTimeThisWeek}s';
    final minutes = totalPlayTimeThisWeek ~/ 60;
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    return '${hours}h ${remainingMins}m';
  }

  /// Optional: Calculate an arbitrary engagement score (0-100)
  int get engagementScore {
    if (!hasData) return 0;
    // Example: capped at 100. 10 games/week * 10 points = 100. + score bonus
    double score = (gamesPlayedThisWeek * 5.0) + (avgScoreThisWeek * 0.5);
    return score.clamp(0, 100).toInt();
  }

  /// Get trend arrow 'up', 'down', 'flat' based on a naive heuristic for UI
  String get engagementTrend {
    if (!hasData || gamesPlayedThisWeek == 0) return 'flat';
    if (gamesPlayedThisWeek >= 3) return 'up';
    return 'down';
  }
}
