// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'memory.dart';

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
