// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameSession _$GameSessionFromJson(Map<String, dynamic> json) => GameSession(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      gameType: json['game_type'] as String,
      score: (json['score'] as num).toInt(),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      completedAt: DateTime.parse(json['completed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$GameSessionToJson(GameSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'game_type': instance.gameType,
      'score': instance.score,
      'duration_seconds': instance.durationSeconds,
      'completed_at': instance.completedAt.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
