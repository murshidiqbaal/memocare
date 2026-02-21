// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_query.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoiceQueryAdapter extends TypeAdapter<VoiceQuery> {
  @override
  final int typeId = 9;

  @override
  VoiceQuery read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VoiceQuery(
      id: fields[0] as String,
      patientId: fields[1] as String,
      queryText: fields[2] as String,
      responseText: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isSynced: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VoiceQuery obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.queryText)
      ..writeByte(3)
      ..write(obj.responseText)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceQueryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceQuery _$VoiceQueryFromJson(Map<String, dynamic> json) => VoiceQuery(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      queryText: json['query_text'] as String,
      responseText: json['response_text'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$VoiceQueryToJson(VoiceQuery instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'query_text': instance.queryText,
      'response_text': instance.responseText,
      'created_at': instance.createdAt.toIso8601String(),
    };
