import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'caregiver_patient_link.g.dart';

/// Caregiver-Patient link model for secure invite code flow
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
  @JsonKey(name: 'linked_at')
  final DateTime linkedAt;

  // Optional fields for UI display (fetched via Supabase joins)
  @HiveField(4)
  @JsonKey(name: 'patient_email')
  final String? patientEmail;

  @HiveField(5)
  @JsonKey(name: 'caregiver_email')
  final String? caregiverEmail;

  @HiveField(6)
  @JsonKey(name: 'patient_name')
  final String? patientName;

  @HiveField(7)
  @JsonKey(name: 'caregiver_name')
  final String? caregiverName;

  CaregiverPatientLink({
    required this.id,
    required this.caregiverId,
    required this.patientId,
    required this.linkedAt,
    this.patientEmail,
    this.caregiverEmail,
    this.patientName,
    this.caregiverName,
  });

  factory CaregiverPatientLink.fromJson(Map<String, dynamic> json) =>
      _$CaregiverPatientLinkFromJson(json);

  Map<String, dynamic> toJson() => _$CaregiverPatientLinkToJson(this);

  CaregiverPatientLink copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    DateTime? linkedAt,
    String? patientEmail,
    String? caregiverEmail,
    String? patientName,
    String? caregiverName,
  }) {
    return CaregiverPatientLink(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      linkedAt: linkedAt ?? this.linkedAt,
      patientEmail: patientEmail ?? this.patientEmail,
      caregiverEmail: caregiverEmail ?? this.caregiverEmail,
      patientName: patientName ?? this.patientName,
      caregiverName: caregiverName ?? this.caregiverName,
    );
  }

  /// Convenience getters for UI compatibility
  bool get isPrimary => false;
  String? get patientPhotoUrl => null;
  String? get relationship => null;
}
