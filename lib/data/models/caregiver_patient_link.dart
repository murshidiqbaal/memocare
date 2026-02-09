import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'caregiver_patient_link.g.dart';

/// Caregiver-Patient link model
/// Represents the relationship between a caregiver and their assigned patients
@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 7)
class CaregiverPatientLink extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'caregiver_id')
  final String caregiverId;

  @HiveField(2)
  @JsonKey(name: 'patient_id')
  final String patientId;

  @HiveField(3)
  @JsonKey(name: 'patient_name')
  final String patientName;

  @HiveField(4)
  @JsonKey(name: 'patient_photo_url')
  final String? patientPhotoUrl;

  @HiveField(5)
  @JsonKey(name: 'relationship')
  final String?
      relationship; // e.g., "Son", "Daughter", "Professional Caregiver"

  @HiveField(6)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(7)
  @JsonKey(name: 'is_primary')
  final bool isPrimary; // Primary caregiver flag

  CaregiverPatientLink({
    required this.id,
    required this.caregiverId,
    required this.patientId,
    required this.patientName,
    this.patientPhotoUrl,
    this.relationship,
    required this.createdAt,
    this.isPrimary = false,
  });

  factory CaregiverPatientLink.fromJson(Map<String, dynamic> json) =>
      _$CaregiverPatientLinkFromJson(json);

  Map<String, dynamic> toJson() => _$CaregiverPatientLinkToJson(this);

  CaregiverPatientLink copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    String? patientName,
    String? patientPhotoUrl,
    String? relationship,
    DateTime? createdAt,
    bool? isPrimary,
  }) {
    return CaregiverPatientLink(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      relationship: relationship ?? this.relationship,
      createdAt: createdAt ?? this.createdAt,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
