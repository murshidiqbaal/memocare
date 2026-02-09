import 'package:uuid/uuid.dart';

class SafeZone {
  final String id;
  final String patientId;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  final DateTime createdAt;
  final String? name; // "Home", "Park"

  SafeZone({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.createdAt,
    this.name,
  });

  factory SafeZone.create({
    required String patientId,
    required double lat,
    required double lng,
    required double radius,
    String? name,
  }) {
    return SafeZone(
      id: const Uuid().v4(),
      patientId: patientId,
      latitude: lat,
      longitude: lng,
      radius: radius,
      createdAt: DateTime.now(),
      name: name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'created_at': createdAt.toIso8601String(),
      'name': name,
    };
  }

  factory SafeZone.fromJson(Map<String, dynamic> json) {
    return SafeZone(
      id: json['id'],
      patientId: json['patient_id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: (json['radius'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      name: json['name'],
    );
  }
}
