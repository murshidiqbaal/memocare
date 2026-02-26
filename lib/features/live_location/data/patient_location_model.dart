/// Model representing a patient's real-time location record from `patient_locations` table.
///
/// Table schema:
///   id          - UUID (PK)
///   patient_id  - UUID (FK → patient_profiles.id)
///   latitude    - double precision
///   longitude   - double precision
///   updated_at  - timestamptz
class PatientLocation {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const PatientLocation({
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
      latitude: _parseDouble(json['latitude']) ?? 0.0,
      longitude: _parseDouble(json['longitude']) ?? 0.0,
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'updated_at': updatedAt.toIso8601String(),
      };

  PatientLocation copyWith({
    String? id,
    String? patientId,
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return PatientLocation(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// How stale this location is
  bool get isStale =>
      DateTime.now().difference(updatedAt) > const Duration(minutes: 10);

  bool get isRecent =>
      DateTime.now().difference(updatedAt) < const Duration(minutes: 2);

  @override
  String toString() =>
      'PatientLocation(patientId: $patientId, lat: $latitude, lng: $longitude, at: $updatedAt)';

  // ── Helpers ────────────────────────────────────────────────────────────────

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value.toLocal();
    final parsed = DateTime.tryParse(value.toString());
    return parsed?.toLocal() ?? DateTime.now();
  }
}
