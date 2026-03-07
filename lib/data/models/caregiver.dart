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
    final dynamic profile = json['profiles'];
    Map<String, dynamic> data = json;

    if (profile is Map<String, dynamic>) {
      data = {...profile, ...json};
    }

    return Caregiver(
      id: (data['id'] ?? data['caregiver_id']) as String?,
      userId: (data['user_id'] ?? data['id']) as String?,
      fullName: (data['full_name'] ?? data['fullName']) as String?,
      phone: (data['phone_number'] ?? data['phone']) as String?,
      relationship: json['relationship'] as String?,
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
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
