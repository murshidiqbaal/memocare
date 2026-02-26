import 'package:json_annotation/json_annotation.dart';

part 'memory.g.dart';

@JsonSerializable(explicitToJson: true)
class Memory {
  final String id;

  @JsonKey(name: 'patient_id')
  final String patientId;

  final String title;

  final String? description;

  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @JsonKey(name: 'voice_audio_url')
  final String? voiceAudioUrl;

  @JsonKey(name: 'event_date')
  final DateTime? eventDate;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localPhotoPath;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localAudioPath;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.patientId,
    required this.title,
    this.description,
    this.imageUrl,
    this.voiceAudioUrl,
    this.eventDate,
    this.localPhotoPath,
    this.localAudioPath,
    required this.createdAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) => _$MemoryFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryToJson(this);

  Memory copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    String? imageUrl,
    String? voiceAudioUrl,
    DateTime? eventDate,
    String? localPhotoPath,
    String? localAudioPath,
    DateTime? createdAt,
  }) {
    return Memory(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      voiceAudioUrl: voiceAudioUrl ?? this.voiceAudioUrl,
      eventDate: eventDate ?? this.eventDate,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
