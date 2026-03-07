class GameAnalytics {
  final String id;
  final String patientId;
  final String gameType;
  final int sessionCount;
  final double avgScore;
  final int bestScore;
  final int totalDurationSeconds;
  final DateTime analyticsDate;

  GameAnalytics({
    required this.id,
    required this.patientId,
    required this.gameType,
    required this.sessionCount,
    required this.avgScore,
    required this.bestScore,
    required this.totalDurationSeconds,
    required this.analyticsDate,
  });

  factory GameAnalytics.fromJson(Map<String, dynamic> json) {
    return GameAnalytics(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      gameType: json['game_type'] as String,
      sessionCount: (json['session_count'] as num?)?.toInt() ?? 0,
      avgScore: (json['avg_score'] as num?)?.toDouble() ?? 0.0,
      bestScore: (json['best_score'] as num?)?.toInt() ?? 0,
      totalDurationSeconds:
          (json['total_duration_seconds'] as num?)?.toInt() ?? 0,
      analyticsDate: json['analytics_date'] != null
          ? DateTime.parse(json['analytics_date'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'game_type': gameType,
      'session_count': sessionCount,
      'avg_score': avgScore,
      'best_score': bestScore,
      'total_duration_seconds': totalDurationSeconds,
      'analytics_date': analyticsDate.toIso8601String().split('T').first,
    };
  }

  GameAnalytics copyWith({
    String? id,
    String? patientId,
    String? gameType,
    int? sessionCount,
    double? avgScore,
    int? bestScore,
    int? totalDurationSeconds,
    DateTime? analyticsDate,
  }) {
    return GameAnalytics(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      gameType: gameType ?? this.gameType,
      sessionCount: sessionCount ?? this.sessionCount,
      avgScore: avgScore ?? this.avgScore,
      bestScore: bestScore ?? this.bestScore,
      totalDurationSeconds: totalDurationSeconds ?? this.totalDurationSeconds,
      analyticsDate: analyticsDate ?? this.analyticsDate,
    );
  }
}
