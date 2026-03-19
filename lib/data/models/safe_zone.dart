class SafeZone {
  final String patientId;
  final double homeLat;
  final double homeLng;
  final double radius;
  final String id;
  final int radiusMeters;
  final String label;
  final DateTime createdAt;
  final double latitude;
  final DateTime updatedAt;
  final double longitude;

  SafeZone({
    required this.patientId,
    required this.homeLat,
    required this.homeLng,
    this.radius = 50.0,
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
      patientId:
          json['patient_id'] as String? ?? (json['patientId'] as String? ?? ''),
      homeLat: (json['home_lat'] ?? json['homeLat'] ?? 0.0) as double,
      homeLng: (json['home_lng'] ?? json['homeLng'] ?? 0.0) as double,
      radius: (json['radius'] ?? 50.0) as double,
      id: json['id'] as String? ?? (json['id'] as String? ?? ''),
      radiusMeters:
          json['radiusMeters'] as int? ?? (json['radiusMeters'] as int? ?? 0),
      label: json['label'] as String? ?? (json['label'] as String? ?? ''),
      createdAt: json['createdAt'] as DateTime? ??
          (json['createdAt'] as DateTime? ?? DateTime.now()),
      latitude:
          json['latitude'] as double? ?? (json['latitude'] as double? ?? 0.0),
      updatedAt: json['updatedAt'] as DateTime? ??
          (json['updatedAt'] as DateTime? ?? DateTime.now()),
      longitude:
          json['longitude'] as double? ?? (json['longitude'] as double? ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'patient_id': patientId,
      'home_lat': homeLat,
      'home_lng': homeLng,
      'radius': radius,
    };
  }
}
