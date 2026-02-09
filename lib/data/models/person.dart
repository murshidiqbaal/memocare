import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'person.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 4)
class Person extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'patient_id')
  final String patientId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String relationship;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  @HiveField(6)
  @JsonKey(name: 'voice_audio_url')
  final String? voiceAudioUrl;

  @HiveField(7)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localPhotoPath;

  @HiveField(8)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localAudioPath;

  @HiveField(9)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(10)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isSynced;

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
    this.isSynced = true,
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
    bool? isSynced,
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
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
