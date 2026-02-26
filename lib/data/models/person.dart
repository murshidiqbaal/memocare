import 'package:json_annotation/json_annotation.dart';

part 'person.g.dart';

@JsonSerializable(explicitToJson: true)
class Person {
  final String id;

  @JsonKey(name: 'patient_id')
  final String patientId;

  final String name;

  final String relationship;

  final String? description;

  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  @JsonKey(name: 'voice_audio_url')
  final String? voiceAudioUrl;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localPhotoPath;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localAudioPath;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Person({
    required this.id,
    required this.patientId,
    required this.name,
    required this.relationship,
    this.description,
    this.photoUrl,
    this.voiceAudioUrl,
    this.localPhotoPath,
    this.localAudioPath,
    required this.createdAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);

  Map<String, dynamic> toJson() => _$PersonToJson(this);

  Person copyWith({
    String? id,
    String? patientId,
    String? name,
    String? relationship,
    String? description,
    String? photoUrl,
    String? voiceAudioUrl,
    String? localPhotoPath,
    String? localAudioPath,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      name: name ?? this.name,
      relationship: relationship ?? this.relationship,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      voiceAudioUrl: voiceAudioUrl ?? this.voiceAudioUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
