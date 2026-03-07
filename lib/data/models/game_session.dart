class GameSession {
  final String id;
  final String patientId;
  final String gameId;
  final String? gameType;
  final int score;
  final int maxScore;
  final int attempts;
  final int durationSeconds;
  final String difficulty;
  final DateTime completedAt;
  final bool isCompleted;
  final double? accuracy;

  GameSession({
    required this.id,
    required this.patientId,
    required this.gameId,
    this.gameType,
    required this.score,
    this.maxScore = 1000,
    this.attempts = 1,
    required this.durationSeconds,
    this.difficulty = 'easy',
    required this.completedAt,
    this.isCompleted = true,
    this.accuracy,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      gameId: (json['game_id'] ?? json['game_type'] ?? '') as String,
      gameType: (json['game_type'] ?? json['game_id']) as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      maxScore: (json['max_score'] as num?)?.toInt() ?? 1000,
      attempts: (json['attempts'] as num?)?.toInt() ?? 1,
      durationSeconds:
          (json['duration_seconds'] ?? json['time_taken_seconds'] as num?)
                  ?.toInt() ??
              0,
      difficulty: json['difficulty_level'] as String? ?? 'easy',
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
      isCompleted: json['is_completed'] as bool? ?? true,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'game_id': gameId,
      'game_type': gameType ?? gameId,
      'score': score,
      'max_score': maxScore,
      'attempts': attempts,
      'duration_seconds': durationSeconds,
      'time_taken_seconds': durationSeconds,
      'difficulty_level': difficulty,
      'completed_at': completedAt.toIso8601String(),
      'is_completed': isCompleted,
      'accuracy': accuracy,
    };
  }

  GameSession copyWith({
    String? id,
    String? patientId,
    String? gameId,
    String? gameType,
    int? score,
    int? maxScore,
    int? attempts,
    int? durationSeconds,
    String? difficulty,
    DateTime? completedAt,
    bool? isCompleted,
    double? accuracy,
  }) {
    return GameSession(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      gameId: gameId ?? this.gameId,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      attempts: attempts ?? this.attempts,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      difficulty: difficulty ?? this.difficulty,
      completedAt: completedAt ?? this.completedAt,
      isCompleted: isCompleted ?? this.isCompleted,
      accuracy: accuracy ?? this.accuracy,
    );
  }
}
