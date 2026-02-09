import '../../../../models/user/profile.dart';

class CaregiverPatientLink {
  final String id;
  final String caregiverId;
  final String patientId;
  final DateTime createdAt;
  final Profile? relatedProfile; // The other person's profile

  CaregiverPatientLink({
    required this.id,
    required this.caregiverId,
    required this.patientId,
    required this.createdAt,
    this.relatedProfile,
  });

  factory CaregiverPatientLink.fromJson(Map<String, dynamic> json) {
    return CaregiverPatientLink(
      id: json['id'],
      caregiverId: json['caregiver_id'],
      patientId: json['patient_id'],
      createdAt: DateTime.parse(json['created_at']),
      relatedProfile: json['related_profile'] != null
          ? Profile.fromJson(json['related_profile'])
          : null,
    );
  }
}
