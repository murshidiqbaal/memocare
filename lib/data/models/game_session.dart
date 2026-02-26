import 'package:json_annotation/json_annotation.dart';

part 'game_session.g.dart';

@JsonSerializable(explicitToJson: true)
class GameSession {
  final String id;

  @JsonKey(name: 'patient_id')
  final String patientId;

  @JsonKey(name: 'game_type')
  final String gameType; // 'memory_match', 'word_puzzle', 'shape_sorter'

  final int score;

  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;

  @JsonKey(name: 'completed_at')
  final DateTime completedAt;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  GameSession({
    required this.id,
    required this.patientId,
    required this.gameType,
    required this.score,
    required this.durationSeconds,
    required this.completedAt,
    required this.createdAt,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) =>
      _$GameSessionFromJson(json);

  Map<String, dynamic> toJson() => _$GameSessionToJson(this);

  GameSession copyWith({
    String? id,
    String? patientId,
    String? gameType,
    int? score,
    int? durationSeconds,
    DateTime? completedAt,
    DateTime? createdAt,
  }) {
    return GameSession(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
