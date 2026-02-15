import 'package:json_annotation/json_annotation.dart';

part 'patient.g.dart';

@JsonSerializable()
class Patient {
  final String id;
  @JsonKey(name: 'full_name') // Joined from profiles
  final String? fullName;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;
  @JsonKey(name: 'medical_notes')
  final String? medicalNotes;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;

  @JsonKey(name: 'phone')
  final String? phone;
  @JsonKey(name: 'linked_at')
  final DateTime? linkedAt;

  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;
  @JsonKey(name: 'gender')
  final String? gender;

  Patient({
    required this.id,
    this.fullName,
    this.profilePhotoUrl,
    this.medicalNotes,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.phone,
    this.linkedAt,
    this.dateOfBirth,
    this.gender,
  });

  factory Patient.fromJson(Map<String, dynamic> json) =>
      _$PatientFromJson(json);
  Map<String, dynamic> toJson() => _$PatientToJson(this);
}
