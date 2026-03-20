class SafeZone {
  final String patientId;
  final String id;
  final int radiusMeters;
  final String label;
  final DateTime createdAt;
  final double latitude;
  final DateTime updatedAt;
  final double longitude;

  SafeZone({
    required this.patientId,
    required this.id,
    required this.radiusMeters,
    required this.label,
    required this.createdAt,
    required this.latitude,
    required this.updatedAt,
    required this.longitude,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      patientId: json['patient_id'] as String? ?? (json['patientId'] as String? ?? ''),
      id: json['id'] as String? ?? (json['id'] as String? ?? ''),
      radiusMeters: json['radius_meters'] as int? ?? (json['radiusMeters'] as int? ?? 1000),
      label: json['label'] as String? ?? (json['label'] as String? ?? ''),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) ?? DateTime.now() : DateTime.now(),
      latitude: json['latitude'] as double? ?? (json['latitude'] as double? ?? 0.0),
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) ?? DateTime.now() : DateTime.now(),
      longitude: json['longitude'] as double? ?? (json['longitude'] as double? ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'label': label,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}

