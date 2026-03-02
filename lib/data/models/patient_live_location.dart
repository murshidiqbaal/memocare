class PatientLiveLocation {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  PatientLiveLocation({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  factory PatientLiveLocation.fromJson(Map<String, dynamic> json) {
    return PatientLiveLocation(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
