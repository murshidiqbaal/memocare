import 'package:json_annotation/json_annotation.dart';

part 'safe_zone.g.dart';

@JsonSerializable(explicitToJson: true)
class SafeZone {
  final String id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  @JsonKey(name: 'centerLatitude')
  final double centerLatitude;
  @JsonKey(name: 'centerLongitude')
  final double centerLongitude;
  @JsonKey(name: 'radius_meters')
  final int radiusMeters;
  final String label;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  SafeZone({
    required this.id,
    required this.patientId,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    required this.label,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SafeZone.fromJson(Map<String, dynamic> json) =>
      _$SafeZoneFromJson(json);

  Map<String, dynamic> toJson() => _$SafeZoneToJson(this);

  SafeZone copyWith({
    String? id,
    String? patientId,
    double? centerLatitude,
    double? centerLongitude,
    int? radiusMeters,
    String? label,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SafeZone(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      centerLatitude: centerLatitude ?? this.centerLatitude,
      centerLongitude: centerLongitude ?? this.centerLongitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
