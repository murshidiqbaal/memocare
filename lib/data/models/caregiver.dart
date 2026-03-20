class Caregiver {
  final String? id;
  final String? userId;
  final String? fullName;
  final String? phone;
  final String? relationship;
  final bool notificationEnabled;
  final String? profilePhotoUrl;
  final DateTime? createdAt;

  // Personal
  final String? email;
  final String? address;
  final DateTime? dateOfBirth;
  final List<String>? languages;

  // Professional
  final int? yearsOfExperience;
  final String? qualification;
  final String? licenseNumber;
  final List<String>? certifications;

  // Availability
  final String? shiftHours;
  final String? careType;
  final List<int>? availableDays;
  final bool? emergencyAvailable;

  // Care log
  final List<String>? careNotes;

  Caregiver({
    this.id,
    this.userId,
    this.fullName,
    this.phone,
    this.relationship,
    this.notificationEnabled = true,
    this.profilePhotoUrl,
    this.createdAt,
    // Personal
    this.email,
    this.address,
    this.dateOfBirth,
    this.languages,
    // Professional
    this.yearsOfExperience,
    this.qualification,
    this.licenseNumber,
    this.certifications,
    // Availability
    this.shiftHours,
    this.careType,
    this.availableDays,
    this.emergencyAvailable,
    // Care log
    this.careNotes,
  });

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    final dynamic nestedCaregiver = json['profile'] ??
        json['caregiver'] ??
        json['caregiver_profiles'] ??
        json['profiles'];
    Map<String, dynamic> data = {};

    if (nestedCaregiver is Map<String, dynamic>) {
      data = nestedCaregiver;
    } else {
      data = json;
    }

    final merged = <String, dynamic>{
      ...data,
      ...json,
    };

    return Caregiver(
      id: (merged['id'] ?? merged['caregiver_id']) as String?,
      userId: (merged['user_id'] ?? merged['id']) as String?,
      fullName: (merged['full_name'] ?? merged['fullName']) as String?,
      phone: (merged['phone_number'] ?? merged['phone']) as String?,
      relationship: merged['relationship'] as String?,
      notificationEnabled: merged['notification_enabled'] as bool? ?? true,
      profilePhotoUrl: merged['profile_photo_url'] as String?,
      createdAt: merged['created_at'] != null
          ? DateTime.tryParse(merged['created_at'] as String)
          : null,

      // Personal
      email: merged['email'] as String?,
      address: merged['address'] as String?,
      dateOfBirth: merged['date_of_birth'] != null
          ? DateTime.tryParse(merged['date_of_birth'] as String)
          : null,
      languages: (merged['languages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),

      // Professional
      yearsOfExperience: merged['years_of_experience'] as int?,
      qualification: merged['qualification'] as String?,
      licenseNumber: merged['license_number'] as String?,
      certifications: (merged['certifications'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),

      // Availability
      shiftHours: merged['shift_hours'] as String?,
      careType: merged['care_type'] as String?,
      availableDays: (merged['available_days'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
      emergencyAvailable: merged['emergency_available'] as bool?,

      // Care log
      careNotes: (merged['care_notes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'phone_number': phone,
      'relationship': relationship,
      'notification_enabled': notificationEnabled,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt?.toIso8601String(),

      // Personal
      'email': email,
      'address': address,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'languages': languages,

      // Professional
      'years_of_experience': yearsOfExperience,
      'qualification': qualification,
      'license_number': licenseNumber,
      'certifications': certifications,

      // Availability
      'shift_hours': shiftHours,
      'care_type': careType,
      'available_days': availableDays,
      'emergency_available': emergencyAvailable,

      // Care log
      'care_notes': careNotes,
    };
  }

  Caregiver copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? phone,
    String? relationship,
    bool? notificationEnabled,
    String? profilePhotoUrl,
    DateTime? createdAt,
    // Personal
    String? email,
    String? address,
    DateTime? dateOfBirth,
    List<String>? languages,
    // Professional
    int? yearsOfExperience,
    String? qualification,
    String? licenseNumber,
    List<String>? certifications,
    // Availability
    String? shiftHours,
    String? careType,
    List<int>? availableDays,
    bool? emergencyAvailable,
    // Care log
    List<String>? careNotes,
  }) {
    return Caregiver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      // Personal
      email: email ?? this.email,
      address: address ?? this.address,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      languages: languages ?? this.languages,
      // Professional
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      qualification: qualification ?? this.qualification,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      certifications: certifications ?? this.certifications,
      // Availability
      shiftHours: shiftHours ?? this.shiftHours,
      careType: careType ?? this.careType,
      availableDays: availableDays ?? this.availableDays,
      emergencyAvailable: emergencyAvailable ?? this.emergencyAvailable,
      // Care log
      careNotes: careNotes ?? this.careNotes,
    );
  }
}
