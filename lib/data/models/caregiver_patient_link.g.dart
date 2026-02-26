// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caregiver_patient_link.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CaregiverPatientLink _$CaregiverPatientLinkFromJson(
        Map<String, dynamic> json) =>
    CaregiverPatientLink(
      id: json['id'] as String,
      caregiverId: json['caregiver_id'] as String,
      patientId: json['patient_id'] as String,
      linkedAt: DateTime.parse(json['linked_at'] as String),
      patientEmail: json['patient_email'] as String?,
      caregiverEmail: json['caregiver_email'] as String?,
      patientName: json['patient_name'] as String?,
      caregiverName: json['caregiver_name'] as String?,
    );

Map<String, dynamic> _$CaregiverPatientLinkToJson(
        CaregiverPatientLink instance) =>
    <String, dynamic>{
      'id': instance.id,
      'caregiver_id': instance.caregiverId,
      'patient_id': instance.patientId,
      'linked_at': instance.linkedAt.toIso8601String(),
      'patient_email': instance.patientEmail,
      'caregiver_email': instance.caregiverEmail,
      'patient_name': instance.patientName,
      'caregiver_name': instance.caregiverName,
    };
