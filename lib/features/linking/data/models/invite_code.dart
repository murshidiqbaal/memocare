class InviteCode {
  final String id;
  final String patientId;
  final String code;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  InviteCode({
    required this.id,
    required this.patientId,
    required this.code,
    required this.expiresAt,
    this.isUsed = false,
    required this.createdAt,
  });

  factory InviteCode.fromJson(Map<String, dynamic> json) {
    return InviteCode(
      id: json['id'],
      patientId: json['patient_id'],
      code: json['code'],
      expiresAt: DateTime.parse(json['expires_at']),
      isUsed: json['used'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
