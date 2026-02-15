// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sos_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SosAlert _$SosAlertFromJson(Map<String, dynamic> json) => SosAlert(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
    );

Map<String, dynamic> _$SosAlertToJson(SosAlert instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'status': instance.status,
      'created_at': instance.createdAt.toIso8601String(),
      'resolved_at': instance.resolvedAt?.toIso8601String(),
    };
