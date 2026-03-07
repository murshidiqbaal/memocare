/// Live location record for a patient's real-time location tracking
class LiveLocation {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;

  LiveLocation({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory LiveLocation.fromJson(Map<String, dynamic> json) {
    return LiveLocation(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: json['recorded_at'] != null
          ? DateTime.parse(json['recorded_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  LiveLocation copyWith({
    String? id,
    String? patientId,
    double? latitude,
    double? longitude,
    DateTime? recordedAt,
  }) {
    return LiveLocation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}
