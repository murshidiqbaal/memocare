import 'package:json_annotation/json_annotation.dart';

part 'sos_alert.g.dart';

@JsonSerializable()
class SosAlert {
  final String id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  final double latitude;
  final double longitude;
  final String status;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;

  SosAlert({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory SosAlert.fromJson(Map<String, dynamic> json) =>
      _$SosAlertFromJson(json);
  Map<String, dynamic> toJson() => _$SosAlertToJson(this);

  bool get isActive => status == 'active';
}
