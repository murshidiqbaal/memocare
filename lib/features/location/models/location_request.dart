/// Model for a location change request.
class LocationRequest {
  final String id;
  final String patientId;
  final String caregiverId;
  final double requestedLatitude;
  final double requestedLongitude;
  final int requestedRadiusMeters;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime createdAt;
  final DateTime? reviewedAt;

  LocationRequest({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.requestedLatitude,
    required this.requestedLongitude,
    required this.requestedRadiusMeters,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
  });

  factory LocationRequest.fromJson(Map<String, dynamic> json) {
    return LocationRequest(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String,
      requestedLatitude: (json['requested_latitude'] as num).toDouble(),
      requestedLongitude: (json['requested_longitude'] as num).toDouble(),
      requestedRadiusMeters: (json['requested_radius_meters'] as num).toInt(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'requested_latitude': requestedLatitude,
      'requested_longitude': requestedLongitude,
      'requested_radius_meters': requestedRadiusMeters,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
