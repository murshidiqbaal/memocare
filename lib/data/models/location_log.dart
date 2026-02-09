import 'package:uuid/uuid.dart';

class LocationLog {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final bool isBreach; // Helps identify alerts quickly

  LocationLog({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.isBreach = false,
  });

  factory LocationLog.create({
    required String patientId,
    required double lat,
    required double lng,
    bool isBreach = false,
  }) {
    return LocationLog(
      id: const Uuid().v4(),
      patientId: patientId,
      latitude: lat,
      longitude: lng,
      recordedAt: DateTime.now(),
      isBreach: isBreach,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'recorded_at': recordedAt.toIso8601String(),
      'is_breach': isBreach,
    };
  }

  factory LocationLog.fromJson(Map<String, dynamic> json) {
    return LocationLog(
      id: json['id'],
      patientId: json['patient_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      recordedAt: DateTime.parse(json['recorded_at']),
      isBreach: json['is_breach'] ?? false,
    );
  }
}
