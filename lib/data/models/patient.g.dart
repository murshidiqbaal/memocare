// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Patient _$PatientFromJson(Map<String, dynamic> json) => Patient(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
    );

Map<String, dynamic> _$PatientToJson(Patient instance) => <String, dynamic>{
      'id': instance.id,
      'full_name': instance.fullName,
      'profile_photo_url': instance.profilePhotoUrl,
      'medical_notes': instance.medicalNotes,
      'emergency_contact_name': instance.emergencyContactName,
      'emergency_contact_phone': instance.emergencyContactPhone,
    };
