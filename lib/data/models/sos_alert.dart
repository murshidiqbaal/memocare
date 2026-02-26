import 'package:json_annotation/json_annotation.dart';

part 'sos_alert.g.dart';

@JsonSerializable(explicitToJson: true)
class SosAlert {
  final String id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  @JsonKey(name: 'caregiver_id')
  final String? caregiverId;
  final String status; // active | acknowledged | resolved
  @JsonKey(name: 'triggered_at')
  final DateTime triggeredAt;
  @JsonKey(name: 'location_lat')
  final double? locationLat;
  @JsonKey(name: 'location_lng')
  final double? locationLng;
  final String? note;

  SosAlert({
    required this.id,
    required this.patientId,
    this.caregiverId,
    this.status = 'active',
    required this.triggeredAt,
    this.locationLat,
    this.locationLng,
    this.note,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) =>
      _$SosAlertFromJson(json);
  Map<String, dynamic> toJson() => _$SosAlertToJson(this);
}
