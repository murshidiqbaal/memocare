import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'voice_query.g.dart';

/// Voice query model for storing patient voice interactions
/// Stores both the question asked and the AI-generated response
@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 9)
class VoiceQuery extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'patient_id')
  final String patientId;

  @HiveField(2)
  @JsonKey(name: 'query_text')
  final String queryText;

  @HiveField(3)
  @JsonKey(name: 'response_text')
  final String responseText;

  @HiveField(4)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(5)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isSynced;

  VoiceQuery({
    required this.id,
    required this.patientId,
    required this.queryText,
    required this.responseText,
    required this.createdAt,
    this.isSynced = true,
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
    bool? isSynced,
  }) {
    return VoiceQuery(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      queryText: queryText ?? this.queryText,
      responseText: responseText ?? this.responseText,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
