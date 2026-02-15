import 'package:json_annotation/json_annotation.dart';

part 'sos_event.g.dart';

@JsonSerializable(explicitToJson: true)
class SosEvent {
  final String id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  @JsonKey(name: 'triggered_at')
  final DateTime triggeredAt;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;
  final double? latitude;
  final double? longitude;

  SosEvent({
    required this.id,
    required this.patientId,
    required this.triggeredAt,
    this.isActive = true,
    this.resolvedAt,
    this.resolvedBy,
    this.latitude,
    this.longitude,
  });

  factory SosEvent.fromJson(Map<String, dynamic> json) =>
      _$SosEventFromJson(json);

  Map<String, dynamic> toJson() => _$SosEventToJson(this);

  SosEvent copyWith({
    String? id,
    String? patientId,
    DateTime? triggeredAt,
    bool? isActive,
    DateTime? resolvedAt,
    String? resolvedBy,
    double? latitude,
    double? longitude,
  }) {
    return SosEvent(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      isActive: isActive ?? this.isActive,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
