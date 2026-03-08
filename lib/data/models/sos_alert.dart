class SosAlert {
  final String id;
  final String patientId;
  final String? caregiverId;
  final String? message;
  final String status; // active | acknowledged | resolved | sent | cancelled
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;
  final double? latitude;
  final double? longitude;
  final String? note;
  final String? patientName;
  final String? patientPhone;

  SosAlert({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.message,
    this.status = 'active',
    required this.triggeredAt,
    this.acknowledgedAt,
    this.resolvedAt,
    double? latitude,
    double? longitude,
    double? locationLat,
    double? locationLng,
    this.note,
    this.patientName,
    this.patientPhone,
  })  : latitude = latitude ?? locationLat,
        longitude = longitude ?? locationLng;

  // Compatibility getters for old field names
  double? get locationLat => latitude;
  double? get locationLng => longitude;
  DateTime get createdAt => triggeredAt;

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    // Created At mapping - support multiple possible keys
    final createdAtStr = (json['created_at'] ??
        json['triggered_at'] ??
        json['sent_at']) as String?;
    final triggeredAt =
        createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();

    return SosAlert(
      id: (json['id'] ?? '') as String,
      patientId: (json['patient_id'] ?? '') as String,
      caregiverId: json['caregiver_id'] as String?,
      message: json['message'] as String?,
      status: (json['status'] ?? 'active') as String,
      triggeredAt: triggeredAt,
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.tryParse(json['acknowledged_at'] as String)
          : null,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      latitude: (json['latitude'] ?? json['location_lat'] as num?)?.toDouble(),
      longitude:
          (json['longitude'] ?? json['location_lng'] as num?)?.toDouble(),
      note: json['note'] as String?,
      patientName: json['patient_name'] as String?,
      patientPhone: json['patient_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'message': message,
      'status': status,
      'created_at': triggeredAt.toIso8601String(),
      'acknowledged_at': acknowledgedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'location_lat': latitude, // compatibility
      'location_lng': longitude, // compatibility
      'note': note,
      'patient_name': patientName,
      'patient_phone': patientPhone,
    };
  }

  // Helper getters for compatibility and logic
  bool get isActive =>
      status == 'active' || status == 'sent' || status == 'pending';
  bool get isResolved => status == 'resolved' || status == 'acknowledged';
  bool get isCancelled => status == 'cancelled';

  String get timeElapsedFormatted {
    final diff = DateTime.now().difference(triggeredAt);
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
    String? message,
    String? status,
    DateTime? triggeredAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
    double? latitude,
    double? longitude,
    String? note,
    String? patientName,
    String? patientPhone,
  }) {
    return SosAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      message: message ?? this.message,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      note: note ?? this.note,
      patientName: patientName ?? this.patientName,
      patientPhone: patientPhone ?? this.patientPhone,
    );
  }
}
