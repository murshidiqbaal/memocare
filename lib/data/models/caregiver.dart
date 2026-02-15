import 'package:json_annotation/json_annotation.dart';

part 'caregiver.g.dart';

@JsonSerializable()
class Caregiver {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  final String? phone;
  final String? relationship;
  @JsonKey(name: 'notification_enabled')
  final bool notificationEnabled;
  @JsonKey(name: 'profile_photo_url')
  final String? profilePhotoUrl;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  // Virtual field from profile join
  @JsonKey(includeFromJson: true, includeToJson: false)
  final String? fullName;

  Caregiver({
    required this.id,
    required this.userId,
    this.phone,
    this.relationship,
    this.notificationEnabled = true,
    this.profilePhotoUrl,
    required this.createdAt,
    this.fullName,
  });

  factory Caregiver.fromJson(Map<String, dynamic> json) =>
      _$CaregiverFromJson(json);

  Map<String, dynamic> toJson() => _$CaregiverToJson(this);

  Caregiver copyWith({
    String? id,
    String? userId,
    String? phone,
    String? relationship,
    bool? notificationEnabled,
    String? profilePhotoUrl,
    DateTime? createdAt,
    String? fullName,
  }) {
    return Caregiver(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      createdAt: createdAt ?? this.createdAt,
      fullName: fullName ?? this.fullName,
    );
  }
}
