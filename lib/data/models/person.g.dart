// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PersonAdapter extends TypeAdapter<Person> {
  @override
  final int typeId = 4;

  @override
  Person read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Person(
      id: fields[0] as String,
      patientId: fields[1] as String,
      name: fields[2] as String,
      relationship: fields[3] as String,
      description: fields[4] as String?,
      photoUrl: fields[5] as String?,
      voiceAudioUrl: fields[6] as String?,
      localPhotoPath: fields[7] as String?,
      localAudioPath: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      isSynced: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Person obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.relationship)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.photoUrl)
      ..writeByte(6)
      ..write(obj.voiceAudioUrl)
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
      other is PersonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      voiceAudioUrl: json['voice_audio_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'name': instance.name,
      'relationship': instance.relationship,
      'description': instance.description,
      'photo_url': instance.photoUrl,
      'voice_audio_url': instance.voiceAudioUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
