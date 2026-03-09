class Caregiver {
  final String? id;
  final String? userId;
  final String? fullName;
  final String? phone;
  final String? relationship;
  final bool notificationEnabled;
  final String? profilePhotoUrl;
  final DateTime? createdAt;

  Caregiver({
    this.id,
    this.userId,
    this.fullName,
    this.phone,
    this.relationship,
    this.notificationEnabled = true,
    this.profilePhotoUrl,
    this.createdAt,
  });

  factory Caregiver.fromJson(Map<String, dynamic> json) {
    // Handle nested caregiver data if present (from join queries)
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

    // Merge root data (like relationship from link table) with caregiver data
    final merged = <String, dynamic>{
      ...data,
      ...json, // json contains relationship from the link table
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'phone': phone,
      'relationship': relationship,
      'notification_enabled': notificationEnabled,
      'profile_photo_url': profilePhotoUrl,
      'created_at': createdAt?.toIso8601String(),
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
    );
  }
}
