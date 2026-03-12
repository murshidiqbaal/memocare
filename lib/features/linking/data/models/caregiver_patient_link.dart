import 'package:memocare/data/models/user/profile.dart';

class CaregiverPatientLink {
  final String id;
  final String caregiverId;
  final String patientId;
  final DateTime linkedAt;
  final DateTime createdAt;
  final String? patientName;
  final String? patientEmail;
  final String? caregiverName;
  final String? caregiverEmail;
  final Profile? relatedProfile; // Optional: the other person's profile

  CaregiverPatientLink({
    required this.id,
    required this.caregiverId,
    required this.patientId,
    required this.linkedAt,
    required this.createdAt,
    this.patientName,
    this.patientEmail,
    this.caregiverName,
    this.caregiverEmail,
    this.relatedProfile,
  });

  factory CaregiverPatientLink.fromJson(Map<String, dynamic> json) {
    return CaregiverPatientLink(
      id: json['id'] as String,
      caregiverId: json['caregiver_id'] as String,
      patientId: json['patient_id'] as String,
      linkedAt: json['linked_at'] != null
          ? DateTime.parse(json['linked_at'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      patientName: json['patient_name'] as String?,
      patientEmail: json['patient_email'] as String?,
      caregiverName: json['caregiver_name'] as String?,
      caregiverEmail: json['caregiver_email'] as String?,
      relatedProfile: json['related_profile'] != null
          ? Profile.fromJson(json['related_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caregiver_id': caregiverId,
      'patient_id': patientId,
      'linked_at': linkedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'patient_name': patientName,
      'patient_email': patientEmail,
      'caregiver_name': caregiverName,
      'caregiver_email': caregiverEmail,
    };
  }

  CaregiverPatientLink copyWith({
    String? id,
    String? caregiverId,
    String? patientId,
    DateTime? linkedAt,
    DateTime? createdAt,
    String? patientName,
    String? patientEmail,
    String? caregiverName,
    String? caregiverEmail,
    Profile? relatedProfile,
  }) {
    return CaregiverPatientLink(
      id: id ?? this.id,
      caregiverId: caregiverId ?? this.caregiverId,
      patientId: patientId ?? this.patientId,
      linkedAt: linkedAt ?? this.linkedAt,
      createdAt: createdAt ?? this.createdAt,
      patientName: patientName ?? this.patientName,
      patientEmail: patientEmail ?? this.patientEmail,
      caregiverName: caregiverName ?? this.caregiverName,
      caregiverEmail: caregiverEmail ?? this.caregiverEmail,
      relatedProfile: relatedProfile ?? this.relatedProfile,
    );
  }
}
