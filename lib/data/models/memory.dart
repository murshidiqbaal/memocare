class Memory {
  final String id;
  final String patientId;
  final String title;
  final String? description;
  final DateTime? eventDate;
  final String? imageUrl;
  final String? voiceAudioUrl;
  final String? localPhotoPath;
  final String? localAudioPath;
  final DateTime createdAt;

  Memory({
    required this.id,
    required this.patientId,
    required this.title,
    this.description,
    this.eventDate,
    this.imageUrl,
    this.voiceAudioUrl,
    this.localPhotoPath,
    this.localAudioPath,
    required this.createdAt,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      eventDate: json['event_date'] != null
          ? DateTime.tryParse(json['event_date'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
      voiceAudioUrl: json['voice_audio_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'title': title,
      'description': description,
      'event_date': eventDate?.toIso8601String(),
      'image_url': imageUrl,
      'voice_audio_url': voiceAudioUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Memory copyWith({
    String? id,
    String? patientId,
    String? title,
    String? description,
    DateTime? eventDate,
    String? imageUrl,
    String? voiceAudioUrl,
    String? localPhotoPath,
    String? localAudioPath,
    DateTime? createdAt,
  }) {
    return Memory(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      description: description ?? this.description,
      eventDate: eventDate ?? this.eventDate,
      imageUrl: imageUrl ?? this.imageUrl,
      voiceAudioUrl: voiceAudioUrl ?? this.voiceAudioUrl,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
