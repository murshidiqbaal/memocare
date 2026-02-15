import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patient_profile.g.dart';

@JsonSerializable()
@HiveType(typeId: 8)
class PatientProfile extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'full_name')
  final String fullName;

  @HiveField(2)
  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;

  @HiveField(3)
  final String? gender;

  @HiveField(4)
  @JsonKey(name: 'phone_number')
  final String? phoneNumber;

  @HiveField(5)
  final String? address;

  @HiveField(6)
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;

  @HiveField(7)
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  @HiveField(8)
  @JsonKey(name: 'medical_notes')
  final String? medicalNotes;

  @HiveField(9)
  @JsonKey(name: 'profile_photo_url')
  final String? profileImageUrl;

  @HiveField(10)
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @HiveField(11)
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @HiveField(12)
  @JsonKey(ignore: true)
  final bool isSynced;

  PatientProfile({
    required this.id,
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
    this.isSynced = true,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) =>
      _$PatientProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PatientProfileToJson(this);

  PatientProfile copyWith({
    String? id,
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
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return PatientProfile(
      id: id ?? this.id,
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
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
