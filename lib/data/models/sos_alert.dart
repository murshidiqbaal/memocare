class SosAlert {
  final String id;
  final String patientId;
  final String? caregiverId;
  final String? message;
  final String status; // pending | acknowledged | resolved
  final DateTime triggeredAt;
  final DateTime? acknowledgedAt;
  final double? locationLat;
  final double? locationLng;
  final String? note;

  SosAlert({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.message,
    this.status = 'pending',
    required this.triggeredAt,
    this.acknowledgedAt,
    this.locationLat,
    this.locationLng,
    this.note,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) {
    return SosAlert(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      // Support both 'created_at' and 'triggered_at' column names
      triggeredAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : (json['triggered_at'] != null
              ? DateTime.parse(json['triggered_at'] as String)
              : DateTime.now()),
      acknowledgedAt: json['acknowledged_at'] != null
          ? DateTime.tryParse(json['acknowledged_at'] as String)
          : null,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      note: json['note'] as String?,
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
      'location_lat': locationLat,
      'location_lng': locationLng,
      'note': note,
    };
  }

  SosAlert copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    String? message,
    String? status,
    DateTime? triggeredAt,
    DateTime? acknowledgedAt,
    double? locationLat,
    double? locationLng,
    String? note,
  }) {
    return SosAlert(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      message: message ?? this.message,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      note: note ?? this.note,
    );
  }
}
