// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emergency_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmergencyAlert _$EmergencyAlertFromJson(Map<String, dynamic> json) =>
    EmergencyAlert(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String?,
      status: $enumDecode(_$EmergencyAlertStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      patientName: json['patient_name'] as String?,
      patientPhone: json['patient_phone'] as String?,
    );

Map<String, dynamic> _$EmergencyAlertToJson(EmergencyAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'caregiver_id': instance.caregiverId,
      'status': _$EmergencyAlertStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'patient_name': instance.patientName,
      'patient_phone': instance.patientPhone,
    };

const _$EmergencyAlertStatusEnumMap = {
  EmergencyAlertStatus.sent: 'sent',
  EmergencyAlertStatus.cancelled: 'cancelled',
  EmergencyAlertStatus.resolved: 'resolved',
};
