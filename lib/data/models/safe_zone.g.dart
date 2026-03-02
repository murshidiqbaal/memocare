// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'safe_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SafeZone _$SafeZoneFromJson(Map<String, dynamic> json) => SafeZone(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      radiusMeters: (json['radius_meters'] as num).toInt(),
      label: json['label'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      centerLatitude: (json['center_latitude'] as num).toDouble(),
      centerLongitude: (json['center_longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$SafeZoneToJson(SafeZone instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'center_latitude': instance.centerLatitude,
      'center_longitude': instance.centerLongitude,
      'radius_meters': instance.radiusMeters,
      'label': instance.label,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
