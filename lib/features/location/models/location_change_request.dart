/// Model for a patient's request to change their home safe zone location.
/// Mapped to the `location_change_requests` Supabase table.
class LocationChangeRequest {
  final String id;
  final String patientId;
  final double requestedLatitude;
  final double requestedLongitude;
  final int requestedRadiusMeters;
  final String status; // 'pending' | 'approved' | 'rejected'
  final String? approvedBy;
  final DateTime createdAt;

  const LocationChangeRequest({
    required this.id,
    required this.patientId,
    required this.requestedLatitude,
    required this.requestedLongitude,
    required this.requestedRadiusMeters,
    required this.status,
    this.approvedBy,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory LocationChangeRequest.fromJson(Map<String, dynamic> json) {
    return LocationChangeRequest(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      requestedLatitude: _toDouble(json['requested_latitude']),
      requestedLongitude: _toDouble(json['requested_longitude']),
      requestedRadiusMeters: (json['requested_radius_meters'] as num?)?.toInt() ?? 150,
      status: json['status'] as String? ?? 'pending',
      approvedBy: json['approved_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'requested_latitude': requestedLatitude,
        'requested_longitude': requestedLongitude,
        'requested_radius_meters': requestedRadiusMeters,
        'status': status,
        'approved_by': approvedBy,
        'created_at': createdAt.toIso8601String(),
      };

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.parse(v);
    return 0.0;
  }
}
