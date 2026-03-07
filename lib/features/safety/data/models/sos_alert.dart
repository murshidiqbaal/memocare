class SosAlert {
  final String id;
  final String patientId;
  final String? caregiverId;
  final double? latitude;
  final double? longitude;
  final String status; // active | acknowledged | resolved | sent | cancelled
  final String? message;
  final DateTime createdAt;
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
    // Normalise incoming fields from different possible tables/versions
    final id = (json['id'] ?? '') as String;
    final patientId = (json['patient_id'] ?? '') as String;
    final caregiverId = json['caregiver_id'] as String?;

    // Location mapping
    final latitude = (json['latitude'] ?? json['location_lat']) as double?;
    final longitude = (json['longitude'] ?? json['location_lng']) as double?;

    final status = (json['status'] ?? 'active') as String;
    final message = json['message'] as String?;

    // Created At mapping
    final createdAtStr = (json['created_at'] ??
        json['triggered_at'] ??
        json['sent_at']) as String?;
    final createdAt =
        createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

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
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'patient_name': patientName,
      'patient_phone': patientPhone,
    };
  }

  // Helper getters for compatibility
  bool get isActive =>
      status == 'active' || status == 'sent' || status == 'pending';
  bool get isResolved => status == 'resolved';
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
