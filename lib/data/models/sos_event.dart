class SosEvent {
  final String id;
  final String patientId;
  final DateTime triggeredAt;
  final bool isActive;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final double? latitude;
  final double? longitude;

  SosEvent({
    required this.id,
    required this.patientId,
    required this.triggeredAt,
    this.isActive = true,
    this.resolvedAt,
    this.resolvedBy,
    this.latitude,
    this.longitude,
  });

  factory SosEvent.fromJson(Map<String, dynamic> json) {
    return SosEvent(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      triggeredAt: json['triggered_at'] != null
          ? DateTime.parse(json['triggered_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.tryParse(json['resolved_at'] as String)
          : null,
      resolvedBy: json['resolved_by'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'triggered_at': triggeredAt.toIso8601String(),
      'is_active': isActive,
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolved_by': resolvedBy,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  SosEvent copyWith({
    String? id,
    String? patientId,
    DateTime? triggeredAt,
    bool? isActive,
    DateTime? resolvedAt,
    String? resolvedBy,
    double? latitude,
    double? longitude,
  }) {
    return SosEvent(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      triggeredAt: triggeredAt ?? this.triggeredAt,
      isActive: isActive ?? this.isActive,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
