// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SosEvent _$SosEventFromJson(Map<String, dynamic> json) => SosEvent(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      resolvedBy: json['resolved_by'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SosEventToJson(SosEvent instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'triggered_at': instance.triggeredAt.toIso8601String(),
      'is_active': instance.isActive,
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'resolved_by': instance.resolvedBy,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
