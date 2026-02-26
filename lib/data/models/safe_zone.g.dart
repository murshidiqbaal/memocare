// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safe_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SafeZone _$SafeZoneFromJson(Map<String, dynamic> json) => SafeZone(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num).toInt(),
      label: json['label'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SafeZoneToJson(SafeZone instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'radius_meters': instance.radiusMeters,
      'label': instance.label,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
