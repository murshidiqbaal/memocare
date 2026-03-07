class Patient {
  final String id;
  final String fullName;
  final String? email;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? gender;
  final DateTime? linkedAt;
  final DateTime? dateOfBirth;
  final String? emergencyContactPhone;
  final int? age;
  final String? condition;

  Patient({
    required this.id,
    required this.fullName,
    this.email,
    this.profileImageUrl,
    this.phoneNumber,
    this.gender,
    this.linkedAt,
    this.dateOfBirth,
    this.emergencyContactPhone,
    this.age,
    this.condition,
  });

  /// Parse from Supabase joined query or simple JSON
  factory Patient.fromJson(Map<String, dynamic> json) {
    // Handle nested profile data if present (from join queries)
    final dynamic profile =
        json['patients'] ?? json['patient_profiles'] ?? json['profiles'];
    Map<String, dynamic> profileData = {};

    if (profile is Map<String, dynamic>) {
      profileData = profile;
    } else if (profile is List && profile.isNotEmpty) {
      profileData = profile.first as Map<String, dynamic>;
    }

    // Merge root data with profile data
    final merged = <String, dynamic>{
      ...profileData,
      ...json,
    };

    return Patient(
      id: (merged['id'] ?? merged['patient_id']) as String? ?? '',
      fullName: (merged['full_name'] ?? merged['fullName']) as String? ??
          'Unknown Patient',
      email: merged['email'] as String?,
      profileImageUrl: (merged['avatar_url'] ??
          merged['profile_photo_url'] ??
          merged['profile_image_url']) as String?,
      phoneNumber: (merged['phone_number'] ??
          merged['phone'] ??
          merged['phoneNumber']) as String?,
      gender: merged['gender'] as String?,
      linkedAt: merged['linked_at'] != null
          ? DateTime.tryParse(merged['linked_at'] as String)
          : null,
      dateOfBirth: merged['date_of_birth'] != null
          ? DateTime.tryParse(merged['date_of_birth'] as String)
          : null,
      emergencyContactPhone: (merged['emergency_contact_phone'] ??
          merged['emergency_phone']) as String?,
      age: merged['age'] as int?,
      condition: merged['condition'] as String?,
    );
  }

  /// Compatibility factory for features/patient_selection
  factory Patient.fromSupabase(Map<String, dynamic> json) =>
      Patient.fromJson(json);

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'profile_image_url': profileImageUrl,
      'phone_number': phoneNumber,
      'gender': gender,
      'linked_at': linkedAt?.toIso8601String(),
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'emergency_contact_phone': emergencyContactPhone,
      'age': age,
      'condition': condition,
    };
  }

  Patient copyWith({
    String? id,
    String? fullName,
    String? email,
    String? profileImageUrl,
    String? phoneNumber,
    String? gender,
    DateTime? linkedAt,
    DateTime? dateOfBirth,
    String? emergencyContactPhone,
    int? age,
    String? condition,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      linkedAt: linkedAt ?? this.linkedAt,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      age: age ?? this.age,
      condition: condition ?? this.condition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Compatibility getter for 'profilePhotoUrl' if used elsewhere
  String? get profilePhotoUrl => profileImageUrl;
}
