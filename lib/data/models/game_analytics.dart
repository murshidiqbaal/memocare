import 'package:json_annotation/json_annotation.dart';

part 'game_analytics.g.dart';

@JsonSerializable(explicitToJson: true)
class GameSession {
  final String? id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  @JsonKey(name: 'game_type')
  final String gameType;
  final int score;
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;
  final double? accuracy;
  @JsonKey(name: 'played_at')
  final DateTime playedAt;

  GameSession({
    this.id,
    required this.patientId,
    required this.gameType,
    required this.score,
    required this.durationSeconds,
    this.accuracy,
    required this.playedAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);

  Map<String, dynamic> toJson() => _$GameSessionToJson(this);
}

@JsonSerializable(explicitToJson: true)
class GameDailyAnalytics {
  final String? id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  final DateTime date;
  @JsonKey(name: 'total_games')
  final int totalGames;
  @JsonKey(name: 'total_duration')
  final int totalDuration;
  @JsonKey(name: 'avg_score')
  final double avgScore;
  @JsonKey(name: 'avg_accuracy')
  final double? avgAccuracy;

  GameDailyAnalytics({
    this.id,
    required this.patientId,
    required this.date,
    required this.totalGames,
    required this.totalDuration,
    required this.avgScore,
    this.avgAccuracy,
  });

  factory GameDailyAnalytics.fromJson(Map<String, dynamic> json) =>
      _$GameDailyAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$GameDailyAnalyticsToJson(this);
}

/// Helper model for aggregated weekly stats on the dashboard
class WeeklyGameStats {
  final int gamesPlayedThisWeek;
  final double avgScoreThisWeek;
  final int totalPlayTimeSeconds;
  final double? avgAccuracyThisWeek;
  final String engagementTrend; // 'up', 'down', 'flat'

  const WeeklyGameStats({
    this.gamesPlayedThisWeek = 0,
    this.avgScoreThisWeek = 0.0,
    this.totalPlayTimeSeconds = 0,
    this.avgAccuracyThisWeek,
    this.engagementTrend = 'flat',
  });
}
