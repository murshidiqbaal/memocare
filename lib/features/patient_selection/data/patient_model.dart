class Patient {
  final String id;
  final String fullName;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? emergencyContactPhone;

  Patient({
    required this.id,
    required this.fullName,
    this.profileImageUrl,
    this.phoneNumber,
    this.emergencyContactPhone,
  });

  /// Parse from Supabase joined query
  /// .from('caregiver_patient_links').select('patient_id, patient_profiles(*)')
  factory Patient.fromSupabase(Map<String, dynamic> json) {
    final dynamic profile = json['patient_profiles'] ?? json['profiles'];
    Map<String, dynamic> profileData = {};

    if (profile is Map<String, dynamic>) {
      profileData = profile;
    } else if (profile is List && profile.isNotEmpty) {
      profileData = profile.first as Map<String, dynamic>;
    }

    return Patient(
      id: json['patient_id'] as String? ?? profileData['id'] as String? ?? '',
      fullName: profileData['full_name'] as String? ?? 'Unknown Patient',
      profileImageUrl: profileData['avatar_url'] as String? ??
          profileData['profile_photo_url'] as String? ??
          profileData['profile_image_url'] as String?,
      phoneNumber: profileData['phone_number'] as String? ??
          profileData['phone'] as String?,
      emergencyContactPhone: profileData['emergency_contact_phone'] as String?,
    );
  }

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown Patient',
      profileImageUrl: json['profile_image_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'profile_image_url': profileImageUrl,
      'phone_number': phoneNumber,
      'emergency_contact_phone': emergencyContactPhone,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
