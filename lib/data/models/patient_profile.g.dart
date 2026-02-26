// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatientProfile _$PatientProfileFromJson(Map<String, dynamic> json) =>
    PatientProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      fullName: json['full_name'] as String,
      dateOfBirth: json['date_of_birth'] == null
          ? null
          : DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String?,
      phoneNumber: json['phone'] as String?,
      address: json['address'] as String?,
      emergencyContactName: json['emergency_contact_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
      medicalNotes: json['medical_notes'] as String?,
      profileImageUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PatientProfileToJson(PatientProfile instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'full_name': instance.fullName,
      'date_of_birth': instance.dateOfBirth?.toIso8601String(),
      'gender': instance.gender,
      'phone': instance.phoneNumber,
      'address': instance.address,
      'emergency_contact_name': instance.emergencyContactName,
      'emergency_contact_phone': instance.emergencyContactPhone,
      'medical_notes': instance.medicalNotes,
      'profile_photo_url': instance.profileImageUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
