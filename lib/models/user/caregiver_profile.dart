class CaregiverProfile {
  final String id;
  final String userId;
  final String fullName;
  final String phoneNumber;
  final String relationship; // e.g., "Child", "Spouse", "Nurse"
  final bool notificationsEnabled;
  final String? photoUrl;
  // Linked patients (read-only list of Patient IDs or basic info)
  final List<String> linkedPatientIds;

  CaregiverProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.relationship,
    this.notificationsEnabled = true,
    this.photoUrl,
    this.linkedPatientIds = const [],
  });

  CaregiverProfile copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phoneNumber,
    String? relationship,
    bool? notificationsEnabled,
    String? photoUrl,
    List<String>? linkedPatientIds,
  }) {
    return CaregiverProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      photoUrl: photoUrl ?? this.photoUrl,
      linkedPatientIds: linkedPatientIds ?? this.linkedPatientIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'relationship': relationship,
      'notifications_enabled': notificationsEnabled,
      'photo_url': photoUrl,
      'linked_patient_ids': linkedPatientIds,
    };
  }

  factory CaregiverProfile.fromJson(Map<String, dynamic> json) {
    return CaregiverProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      phoneNumber: json['phone_number'] as String,
      relationship: json['relationship'] as String,
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      photoUrl: json['photo_url'] as String?,
      linkedPatientIds: (json['linked_patient_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
