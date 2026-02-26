class LocationAlert {
  final String? id;
  final String patientId;
  final String? caregiverId;
  final double? latitude;
  final double? longitude;
  final double? distanceMeters;
  final String status;
  final DateTime? createdAt;

  LocationAlert({
    this.id,
    required this.patientId,
    this.caregiverId,
    this.latitude,
    this.longitude,
    this.distanceMeters,
    this.status = 'active',
    this.createdAt,
  });

  factory LocationAlert.fromJson(Map<String, dynamic> json) {
    return LocationAlert(
      id: json['id'] as String?,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      distanceMeters: json['distance_meters'] != null
          ? (json['distance_meters'] as num).toDouble()
          : null,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'patient_id': patientId,
      if (caregiverId != null) 'caregiver_id': caregiverId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      'status': status,
    };
  }
}
