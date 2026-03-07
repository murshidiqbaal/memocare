class Person {
  final String id;
  final String patientId;
  final String name;
  final String? relationship;
  final String? description;
  final String? photoUrl;
  final String? voiceAudioUrl;
  final String? localPhotoPath;
  final String? localAudioPath;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Person({
    required this.id,
    required this.patientId,
    required this.name,
    this.relationship,
    this.description,
    this.photoUrl,
    this.voiceAudioUrl,
    this.localPhotoPath,
    this.localAudioPath,
    required this.createdAt,
    this.updatedAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      name: json['name'] as String,
      relationship: json['relationship'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      voiceAudioUrl: json['voice_audio_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'name': name,
      'relationship': relationship,
      'description': description,
      'photo_url': photoUrl,
      'voice_audio_url': voiceAudioUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

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
    DateTime? updatedAt,
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
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
