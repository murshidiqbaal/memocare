class PatientLocation {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  PatientLocation({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  factory PatientLocation.fromJson(Map<String, dynamic> json) {
    return PatientLocation(
      id: json['id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
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
