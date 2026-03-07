class VoiceQuery {
  final String id;
  final String patientId;
  final String query;
  final String? response;
  final DateTime createdAt;

  VoiceQuery({
    required this.id,
    required this.patientId,
    required this.query,
    this.response,
    required this.createdAt,
  });

  factory VoiceQuery.fromJson(Map<String, dynamic> json) {
    return VoiceQuery(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      query: json['query'] as String,
      response: json['response'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'query': query,
      'response': response,
      'created_at': createdAt.toIso8601String(),
    };
  }

  VoiceQuery copyWith({
    String? id,
    String? patientId,
    String? query,
    String? response,
    DateTime? createdAt,
  }) {
    return VoiceQuery(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      query: query ?? this.query,
      response: response ?? this.response,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
