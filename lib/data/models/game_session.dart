import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'game_session.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 6)
class GameSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'patient_id')
  final String patientId;

  @HiveField(2)
  @JsonKey(name: 'game_type')
  final String gameType; // 'memory_match', 'word_puzzle', 'shape_sorter'

  @HiveField(3)
  final int score;

  @HiveField(4)
  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;

  @HiveField(5)
  @JsonKey(name: 'completed_at')
  final DateTime completedAt;

  @HiveField(6)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(7)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isSynced;

  GameSession({
    required this.id,
    required this.patientId,
    required this.gameType,
    required this.score,
    required this.durationSeconds,
    required this.completedAt,
    required this.createdAt,
    this.isSynced = true,
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
    bool? isSynced,
  }) {
    return GameSession(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
