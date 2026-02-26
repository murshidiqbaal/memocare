// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_analytics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GameSession _$GameSessionFromJson(Map<String, dynamic> json) => GameSession(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      gameType: json['game_type'] as String,
      score: (json['score'] as num).toInt(),
      durationSeconds: (json['duration_seconds'] as num).toInt(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      playedAt: DateTime.parse(json['played_at'] as String),
    );

Map<String, dynamic> _$GameSessionToJson(GameSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'game_type': instance.gameType,
      'score': instance.score,
      'duration_seconds': instance.durationSeconds,
      'accuracy': instance.accuracy,
      'played_at': instance.playedAt.toIso8601String(),
    };

GameDailyAnalytics _$GameDailyAnalyticsFromJson(Map<String, dynamic> json) =>
    GameDailyAnalytics(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      date: DateTime.parse(json['date'] as String),
      totalGames: (json['total_games'] as num).toInt(),
      totalDuration: (json['total_duration'] as num).toInt(),
      avgScore: (json['avg_score'] as num).toDouble(),
      avgAccuracy: (json['avg_accuracy'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$GameDailyAnalyticsToJson(GameDailyAnalytics instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'date': instance.date.toIso8601String(),
      'total_games': instance.totalGames,
      'total_duration': instance.totalDuration,
      'avg_score': instance.avgScore,
      'avg_accuracy': instance.avgAccuracy,
    };
