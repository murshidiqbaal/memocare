import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'memory.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 5)
class Memory extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'patient_id')
  final String patientId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @HiveField(5)
  @JsonKey(name: 'voice_audio_url')
  final String? voiceAudioUrl;

  @HiveField(6)
  @JsonKey(name: 'event_date')
  final DateTime? eventDate;

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
    this.isSynced = true,
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
    bool? isSynced,
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
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
