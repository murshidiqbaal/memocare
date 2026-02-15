// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveLocation _$LiveLocationFromJson(Map<String, dynamic> json) => LiveLocation(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recorded_at'] as String),
    );

Map<String, dynamic> _$LiveLocationToJson(LiveLocation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'recorded_at': instance.recordedAt.toIso8601String(),
    };
