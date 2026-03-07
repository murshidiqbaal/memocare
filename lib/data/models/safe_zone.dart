class SafeZone {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String label;
  final DateTime createdAt;
  final DateTime updatedAt;

  SafeZone({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num).toInt(),
      label: json['label'] as String? ?? 'Home',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'label': label,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SafeZone copyWith({
    String? id,
    String? patientId,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    String? label,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafeZone(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
