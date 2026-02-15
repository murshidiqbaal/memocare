// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GameSessionAdapter extends TypeAdapter<GameSession> {
  @override
  final int typeId = 6;

  @override
  GameSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GameSession(
      id: fields[0] as String,
      patientId: fields[1] as String,
      gameType: fields[2] as String,
      score: fields[3] as int,
      durationSeconds: fields[4] as int,
      completedAt: fields[5] as DateTime,
      createdAt: fields[6] as DateTime,
      isSynced: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, GameSession obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.gameType)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.durationSeconds)
      ..writeByte(5)
      ..write(obj.completedAt)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

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
