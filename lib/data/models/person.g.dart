// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

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
