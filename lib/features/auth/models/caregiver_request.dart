class CaregiverRequest {
  final String id;
  final String userId;
  final String email;
  final String? fullName;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaregiverRequest({
    required this.id,
    required this.userId,
    required this.email,
    this.fullName,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaregiverRequest.fromJson(Map<String, dynamic> json) {
    return CaregiverRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email': email,
      'full_name': fullName,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CaregiverRequest copyWith({
    String? id,
    String? userId,
    String? email,
    String? fullName,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CaregiverRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
