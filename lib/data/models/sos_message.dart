class SosMessage {
  final String? id;
  final String patientId;
  final String caregiverId;
  final String status; // 'pending', 'viewed', 'resolved'
  final DateTime triggeredAt;
  final double locationLat;
  final double locationLng;
  final String? note;

  SosMessage({
    this.id,
    required this.patientId,
    required this.caregiverId,
    this.status = 'pending',
    required this.triggeredAt,
    required this.locationLat,
    required this.locationLng,
    this.note,
  });

  factory SosMessage.fromJson(Map<String, dynamic> json) {
    return SosMessage(
      id: json['id'] as String?,
      patientId: (json['patient_id'] ?? json['patientId']) as String? ?? '',
      caregiverId: (json['caregiver_id'] ?? json['caregiverId']) as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : (json['triggeredAt'] != null 
              ? DateTime.parse(json['triggeredAt'] as String)
              : DateTime.now()),
      locationLat: (json['location_lat'] ?? json['locationLat'] ?? 0.0) as double,
      locationLng: (json['location_lng'] ?? json['locationLng'] ?? 0.0) as double,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'status': status,
      'triggered_at': triggeredAt.toIso8601String(),
      'location_lat': locationLat,
      'location_lng': locationLng,
      'note': note,
    };
    // Only include 'id' if it's already set — let Supabase auto-generate it otherwise
    if (id != null) map['id'] = id;
    return map;
  }

  SosMessage copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    String? status,
    DateTime? triggeredAt,
    double? locationLat,
    double? locationLng,
    String? note,
  }) {
    return SosMessage(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      note: note ?? this.note,
    );
  }
}
