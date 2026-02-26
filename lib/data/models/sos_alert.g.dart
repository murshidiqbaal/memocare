// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SosAlert _$SosAlertFromJson(Map<String, dynamic> json) => SosAlert(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String?,
      status: json['status'] as String? ?? 'active',
      triggeredAt: DateTime.parse(json['triggered_at'] as String),
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$SosAlertToJson(SosAlert instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'caregiver_id': instance.caregiverId,
      'status': instance.status,
      'triggered_at': instance.triggeredAt.toIso8601String(),
      'location_lat': instance.locationLat,
      'location_lng': instance.locationLng,
      'note': instance.note,
    };
