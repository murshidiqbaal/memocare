class PatientHomeLocation {
  final String? id;
  final String patientId;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PatientHomeLocation({
    this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 1000,
    this.createdAt,
    this.updatedAt,
  });

  factory PatientHomeLocation.fromJson(Map<String, dynamic> json) {
    return PatientHomeLocation(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: json['radius_meters'] as int? ?? 1000,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      // created_at and updated_at are generally handled by the database
    };
  }
}
