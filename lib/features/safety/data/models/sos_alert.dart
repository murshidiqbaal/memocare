class SosAlert {
  final String id;
  final String patientId;
  final String? caregiverId;
  final double? latitude;
  final double? longitude;
  final String status; // active | acknowledged | resolved | sent | cancelled | pending
  final String? message;
  final DateTime createdAt; // Note: triggered_at in DB
  final DateTime? resolvedAt;
  final DateTime? acknowledgedAt;
  final String? patientName;
  final String? patientPhone;

  SosAlert({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.latitude,
    this.longitude,
    required this.status,
    this.message,
    required this.createdAt,
    this.resolvedAt,
    this.acknowledgedAt,
    this.patientName,
    this.patientPhone,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    // Normalise incoming fields to match the internal model
    final id = (json['id'] ?? '') as String;
    final patientId = (json['patient_id'] ?? '') as String;
    final caregiverId = json['caregiver_id'] as String?;

    // Location mapping from DB schema
    final latitude = (json['lat'] as num?)?.toDouble();
    final longitude = (json['lng'] as num?)?.toDouble();

    final status = (json['status'] ?? 'active') as String;
    final message = json['message'] as String?;

    // Time mapping from DB schema (triggered_at)
    final triggeredAtStr = (json['triggered_at'] ?? json['created_at']) as String?;
    final createdAt =
        triggeredAtStr != null ? DateTime.parse(triggeredAtStr) : DateTime.now();

    final resolvedAtStr = json['resolved_at'] as String?;
    final resolvedAt =
        resolvedAtStr != null ? DateTime.parse(resolvedAtStr) : null;

    final acknowledgedAtStr = json['acknowledged_at'] as String?;
    final acknowledgedAt =
        acknowledgedAtStr != null ? DateTime.parse(acknowledgedAtStr) : null;

    final patientName = json['patient_name'] as String?;
    final patientPhone = json['patient_phone'] as String?;

    return SosAlert(
      id: id,
      patientId: patientId,
      caregiverId: caregiverId,
      latitude: latitude,
      longitude: longitude,
      status: status,
      message: message,
      createdAt: createdAt,
      resolvedAt: resolvedAt,
      acknowledgedAt: acknowledgedAt,
      patientName: patientName,
      patientPhone: patientPhone,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'lat': latitude,
      'lng': longitude,
      'status': status,
      'message': message,
      'triggered_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'patient_name': patientName,
      'patient_phone': patientPhone,
    };
  }

  // Helper getters
  bool get isActive =>
      status == 'active' || status == 'sent' || status == 'pending';
  bool get isResolved => status == 'resolved' || status == 'acknowledged';
  bool get isCancelled => status == 'cancelled';

  String get timeElapsedFormatted {
    final diff = DateTime.now().difference(createdAt);
    final minutes = diff.inMinutes;
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    final hours = diff.inHours;
    if (hours < 24) return '$hours hour${hours > 1 ? 's' : ''} ago';
    final days = diff.inDays;
    return '$days day${days > 1 ? 's' : ''} ago';
  }

  SosAlert copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    double? latitude,
    double? longitude,
    String? status,
    String? message,
    DateTime? createdAt,
    DateTime? resolvedAt,
    DateTime? acknowledgedAt,
    String? patientName,
    String? patientPhone,
  }) {
    return SosAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
    );
  }
}
