import 'package:json_annotation/json_annotation.dart';

part 'patient_profile.g.dart';

@JsonSerializable()
class PatientProfile {
  final String id;

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'full_name')
  final String fullName;

  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;

  final String? gender;

  @JsonKey(name: 'phone') // ✅ FIXED
  final String? phoneNumber;

  final String? address;

  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;

  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  @JsonKey(name: 'medical_notes')
  final String? medicalNotes;

  @JsonKey(name: 'profile_photo_url')
  final String? profileImageUrl;

  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  PatientProfile({
    required this.id,
    this.userId,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.medicalNotes,
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) =>
      _$PatientProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PatientProfileToJson(this);

  PatientProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? medicalNotes,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return PatientProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      medicalNotes: medicalNotes ?? this.medicalNotes,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
