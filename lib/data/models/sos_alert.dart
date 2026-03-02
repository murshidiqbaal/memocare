import 'package:json_annotation/json_annotation.dart';

part 'sos_alert.g.dart';

@JsonSerializable(explicitToJson: true)
class SosAlert {
  final String id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  @JsonKey(name: 'caregiver_id')
  final String? caregiverId;
  final String? message; // Added per prompt
  final String status; // active | acknowledged | resolved
  @JsonKey(name: 'created_at') // Renamed from triggered_at per prompt
  final DateTime triggeredAt;
  @JsonKey(name: 'acknowledged_at')
  final DateTime? acknowledgedAt;
  @JsonKey(name: 'location_lat')
  final double? locationLat;
  @JsonKey(name: 'location_lng')
  final double? locationLng;
  final String? note;

  SosAlert({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.message,
    this.status = 'pending',
    required this.triggeredAt,
    this.acknowledgedAt,
    this.locationLat,
    this.locationLng,
    this.note,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) =>
      _$SosAlertFromJson(json);
  Map<String, dynamic> toJson() => _$SosAlertToJson(this);
}
