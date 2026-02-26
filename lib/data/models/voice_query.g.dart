// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voice_query.dart';

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
