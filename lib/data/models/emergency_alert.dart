/// Emergency alert status enum
enum EmergencyAlertStatus {
  active,
  cancelled,
  resolved,
}

/// Emergency Alert Model
/// Represents an SOS emergency alert sent by a patient
class EmergencyAlert {
  final String id;
  final String patientId;
  final String? caregiverId;
  final EmergencyAlertStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final double? latitude;
  final double? longitude;
  final String? patientName;
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

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    return EmergencyAlert(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String?,
      status: _statusFromString(json['status'] as String? ?? 'active'),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      latitude: (json['lat'] as num?)?.toDouble(),
      longitude: (json['lng'] as num?)?.toDouble(),
      patientName: json['patient_name'] as String?,
      patientPhone: json['patient_phone'] as String?,
    );
  }

  static EmergencyAlertStatus _statusFromString(String s) {
    switch (s) {
      case 'cancelled':
        return EmergencyAlertStatus.cancelled;
      case 'resolved':
        return EmergencyAlertStatus.resolved;
      default:
        return EmergencyAlertStatus.active;
    }
  }

  static String _statusToString(EmergencyAlertStatus s) {
    switch (s) {
      case EmergencyAlertStatus.cancelled:
        return 'cancelled';
      case EmergencyAlertStatus.resolved:
        return 'resolved';
      case EmergencyAlertStatus.active:
        return 'active';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'status': _statusToString(status),
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'lat': latitude,
      'lng': longitude,
      'patient_name': patientName,
      'patient_phone': patientPhone,
    };
  }

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
  bool get isActive => status == EmergencyAlertStatus.active;

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
