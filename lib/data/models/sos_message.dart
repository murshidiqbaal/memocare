class SosMessage {
  final String? id;
  final String patientId;
  final String? caregiverId;
  final String status; // 'pending', 'active', 'resolved', 'acknowledged'
  final DateTime triggeredAt;
  final double latitude;
  final double longitude;
  final String? note;

  SosMessage({
    this.id,
    required this.patientId,
    this.caregiverId,
    this.status = 'active',
    required this.triggeredAt,
    required this.latitude,
    required this.longitude,
    this.note,
  });

  factory SosMessage.fromJson(Map<String, dynamic> json) {
    return SosMessage(
      id: json['id'] as String?,
      patientId: (json['patient_id'] ?? '') as String,
      caregiverId: json['caregiver_id'] as String?,
      status: (json['status'] ?? 'pending') as String,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : DateTime.now(),
      latitude: (json['lat'] as num? ?? 0.0).toDouble(),
      longitude: (json['lng'] as num? ?? 0.0).toDouble(),
      note: (json['note'] ?? json['message']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'status': status,
      'triggered_at': triggeredAt.toUtc().toIso8601String(),
      'lat': latitude,
      'lng': longitude,
      'note': note,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  SosMessage copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    String? status,
    DateTime? triggeredAt,
    double? latitude,
    double? longitude,
    String? note,
  }) {
    return SosMessage(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      status: status ?? this.status,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      note: note ?? this.note,
    );
  }
}
