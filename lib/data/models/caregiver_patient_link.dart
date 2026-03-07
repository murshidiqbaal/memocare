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
  final String? patientPhotoUrl;
  final String? relationship;
  final bool isPrimary;

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
    this.patientPhotoUrl,
    this.relationship,
    this.isPrimary = false,
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
      patientPhotoUrl: json['patient_photo_url'] as String?,
      relationship: json['relationship'] as String?,
      isPrimary: json['is_primary'] as bool? ?? false,
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
      'patient_photo_url': patientPhotoUrl,
      'relationship': relationship,
      'is_primary': isPrimary,
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
    String? patientPhotoUrl,
    String? relationship,
    bool? isPrimary,
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
      patientPhotoUrl: patientPhotoUrl ?? this.patientPhotoUrl,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
    );
  }
}
