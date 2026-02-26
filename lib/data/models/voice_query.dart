import 'package:json_annotation/json_annotation.dart';

part 'voice_query.g.dart';

/// Voice query model for storing patient voice interactions
/// Stores both the question asked and the AI-generated response
@JsonSerializable(explicitToJson: true)
class VoiceQuery {
  final String id;

  @JsonKey(name: 'patient_id')
  final String patientId;

  @JsonKey(name: 'query_text')
  final String queryText;

  @JsonKey(name: 'response_text')
  final String responseText;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  VoiceQuery({
    required this.id,
    required this.patientId,
    required this.queryText,
    required this.responseText,
    required this.createdAt,
  });

  factory VoiceQuery.fromJson(Map<String, dynamic> json) =>
      _$VoiceQueryFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceQueryToJson(this);

  VoiceQuery copyWith({
    String? id,
    String? patientId,
    String? queryText,
    String? responseText,
    DateTime? createdAt,
  }) {
    return VoiceQuery(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      queryText: queryText ?? this.queryText,
      responseText: responseText ?? this.responseText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
