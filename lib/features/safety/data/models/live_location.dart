import 'package:json_annotation/json_annotation.dart';

part 'live_location.g.dart';

@JsonSerializable()
class LiveLocation {
  final String id;
  @JsonKey(name: 'patient_id')
  final String patientId;
  final double latitude;
  final double longitude;
  @JsonKey(name: 'recorded_at')
  final DateTime recordedAt;

  LiveLocation({
    required this.id,
    required this.patientId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
  });

  factory LiveLocation.fromJson(Map<String, dynamic> json) =>
      _$LiveLocationFromJson(json);
  Map<String, dynamic> toJson() => _$LiveLocationToJson(this);
}
