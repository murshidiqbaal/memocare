class PatientLocation {
  final String? id;
  final String patientId;
  final double lat;
  final double lng;
  final DateTime updatedAt;

  PatientLocation({
    this.id,
    required this.patientId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
  });

  factory PatientLocation.fromJson(Map<String, dynamic> json) {
    return PatientLocation(
      id: json['id'] as String?,
      patientId: (json['patient_id'] ?? json['patientId']) as String? ?? '',
      lat: (json['lat'] ?? 0.0) as double,
      lng: (json['lng'] ?? 0.0) as double,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : (json['updatedAt'] != null 
              ? DateTime.parse(json['updatedAt'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'patient_id': patientId,
      'lat': lat,
      'lng': lng,
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
    if (id != null) map['id'] = id;
    return map;
  }

  PatientLocation copyWith({
    String? id,
    String? patientId,
    double? lat,
    double? lng,
    DateTime? updatedAt,
  }) {
    return PatientLocation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
