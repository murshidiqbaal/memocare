import 'package:json_annotation/json_annotation.dart';

part 'emergency_alert.g.dart';

/// Emergency alert status enum
enum EmergencyAlertStatus {
  @JsonValue('sent')
  sent,
  @JsonValue('cancelled')
  cancelled,
  @JsonValue('resolved')
  resolved,
}

/// Emergency Alert Model
/// Represents an SOS emergency alert sent by a patient
@JsonSerializable(explicitToJson: true)
class EmergencyAlert {
  final String id;

  @JsonKey(name: 'patient_id')
  final String patientId;

  @JsonKey(name: 'caregiver_id')
  final String? caregiverId;

  final EmergencyAlertStatus status;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;

  final double? latitude;
  final double? longitude;

  @JsonKey(name: 'patient_name')
  final String? patientName;

  @JsonKey(name: 'patient_phone')
  final String? patientPhone;

  EmergencyAlert({
    required this.id,
    required this.patientId,
    this.caregiverId,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.latitude,
    this.longitude,
    this.patientName,
    this.patientPhone,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) =>
      _$EmergencyAlertFromJson(json);

  Map<String, dynamic> toJson() => _$EmergencyAlertToJson(this);

  EmergencyAlert copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    EmergencyAlertStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    double? latitude,
    double? longitude,
    String? patientName,
    String? patientPhone,
  }) {
    return EmergencyAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
    );
  }

  /// Check if alert is active
  bool get isActive => status == EmergencyAlertStatus.sent;

  /// Check if alert is resolved
  bool get isResolved => status == EmergencyAlertStatus.resolved;

  /// Check if alert was cancelled
  bool get isCancelled => status == EmergencyAlertStatus.cancelled;

  /// Get time elapsed since alert was created
  Duration get timeElapsed => DateTime.now().difference(createdAt);

  /// Get formatted time elapsed (e.g., "2 minutes ago")
  String get timeElapsedFormatted {
    final minutes = timeElapsed.inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    final hours = timeElapsed.inHours;
    if (hours < 24) return '$hours hour${hours > 1 ? 's' : ''} ago';
    final days = timeElapsed.inDays;
    return '$days day${days > 1 ? 's' : ''} ago';
  }
}
