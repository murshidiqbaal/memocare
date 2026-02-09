// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MemoryAdapter extends TypeAdapter<Memory> {
  @override
  final int typeId = 5;

  @override
  Memory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Memory(
      id: fields[0] as String,
      patientId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      imageUrl: fields[4] as String?,
      voiceAudioUrl: fields[5] as String?,
      eventDate: fields[6] as DateTime?,
      localPhotoPath: fields[7] as String?,
      localAudioPath: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      isSynced: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Memory obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.voiceAudioUrl)
      ..writeByte(6)
      ..write(obj.eventDate)
      ..writeByte(7)
      ..write(obj.localPhotoPath)
      ..writeByte(8)
      ..write(obj.localAudioPath)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Memory _$MemoryFromJson(Map<String, dynamic> json) => Memory(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      voiceAudioUrl: json['voice_audio_url'] as String?,
      eventDate: json['event_date'] == null
          ? null
          : DateTime.parse(json['event_date'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MemoryToJson(Memory instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'title': instance.title,
      'description': instance.description,
      'image_url': instance.imageUrl,
      'voice_audio_url': instance.voiceAudioUrl,
      'event_date': instance.eventDate?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };
