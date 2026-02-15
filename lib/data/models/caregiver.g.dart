// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'caregiver.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Caregiver _$CaregiverFromJson(Map<String, dynamic> json) => Caregiver(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      phone: json['phone'] as String?,
      relationship: json['relationship'] as String?,
      notificationEnabled: json['notification_enabled'] as bool? ?? true,
      profilePhotoUrl: json['profile_photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      fullName: json['fullName'] as String?,
    );

Map<String, dynamic> _$CaregiverToJson(Caregiver instance) => <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'phone': instance.phone,
      'relationship': instance.relationship,
      'notification_enabled': instance.notificationEnabled,
      'profile_photo_url': instance.profilePhotoUrl,
      'created_at': instance.createdAt.toIso8601String(),
    };
