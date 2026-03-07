class SosMessage {
  final String id;
  final String patientId;
  final String? patientName;
  final String? messageText;
  final DateTime createdAt;
  final bool isMarkedAsRead;
  final String? messageType; // e.g., 'EMERGENCY', 'ALERT', 'INFO'
  final Map<String, dynamic>? additionalData;

  SosMessage({
    required this.id,
    required this.patientId,
    this.patientName,
    this.messageText,
    required this.createdAt,
    this.isMarkedAsRead = false,
    this.messageType,
    this.additionalData,
  });

  // Factory constructor to create from Firestore/API JSON
  factory SosMessage.fromJson(Map<String, dynamic> json) {
    return SosMessage(
      id: json['id'] ?? '',
      patientId: json['patient_id'] ?? '',
      patientName: json['patient_name'],
      messageText: json['message_text'] ?? json['message'],
      createdAt: json['created_at'] is DateTime
          ? json['created_at']
          : DateTime.parse(
              json['created_at'] ?? DateTime.now().toIso8601String()),
      isMarkedAsRead: json['is_marked_as_read'] ?? json['is_read'] ?? false,
      messageType: json['message_type'] ?? json['type'],
      additionalData: json['additional_data'],
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'patient_name': patientName,
      'message_text': messageText,
      'created_at': createdAt.toIso8601String(),
      'is_marked_as_read': isMarkedAsRead,
      'message_type': messageType,
      'additional_data': additionalData,
    };
  }

  // Copy with method
  SosMessage copyWith({
    String? id,
    String? patientId,
    String? patientName,
    String? messageText,
    DateTime? createdAt,
    bool? isMarkedAsRead,
    String? messageType,
    Map<String, dynamic>? additionalData,
  }) {
    return SosMessage(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      patientName: patientName ?? this.patientName,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      isMarkedAsRead: isMarkedAsRead ?? this.isMarkedAsRead,
      messageType: messageType ?? this.messageType,
      additionalData: additionalData ?? this.additionalData,
    );
  }
}
