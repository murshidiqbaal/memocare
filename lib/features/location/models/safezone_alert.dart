/// Model for a safe zone breach/return alert.
/// Mapped to the `safezone_alerts` Supabase table.
class SafeZoneAlert {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final SafeZoneAlertType alertType;
  final DateTime createdAt;

  const SafeZoneAlert({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.alertType,
    required this.createdAt,
  });

  factory SafeZoneAlert.fromJson(Map<String, dynamic> json) {
    return SafeZoneAlert(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      alertType: json['alert_type'] == 'returned_home'
          ? SafeZoneAlertType.returnedHome
          : SafeZoneAlertType.leftZone,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'alert_type': alertType == SafeZoneAlertType.leftZone
            ? 'left_zone'
            : 'returned_home',
      };

  static double _toDouble(dynamic v) {
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.parse(v);
    return 0.0;
  }
}

enum SafeZoneAlertType { leftZone, returnedHome }
