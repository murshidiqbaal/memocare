enum ReminderType {
  medication,
  appointment,
  task,
}

enum ReminderFrequency {
  once,
  daily,
  weekly,
  custom,
}

enum ReminderStatus {
  pending,
  completed,
  missed,
}

class Reminder {
  final String id;
  final String patientId;
  final String caregiverId;
  final String title;
  final ReminderType type;
  final String? description;
  final DateTime reminderTime;
  final ReminderFrequency repeatRule;
  final ReminderStatus status;
  final DateTime createdAt;
  final List<DateTime> completionHistory;
  final bool isSnoozed;
  final int? snoozeDurationMinutes;
  final DateTime? lastSnoozedAt;

  // Local only properties (not sent to Supabase)
  final String? localAudioPath;
  final int? notificationId;

  // Keeping this for compatibility in UI but it's local only since it's not in schema
  final String? voiceAudioUrl;

  Reminder({
    required this.id,
    required this.patientId,
    required this.caregiverId,
    required this.title,
    required this.type,
    required this.reminderTime,
    required this.createdAt,
    this.description,
    this.repeatRule = ReminderFrequency.once,
    this.status = ReminderStatus.pending,
    this.completionHistory = const [],
    this.isSnoozed = false,
    this.snoozeDurationMinutes,
    this.lastSnoozedAt,
    this.localAudioPath,
    this.notificationId,
    this.voiceAudioUrl,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      caregiverId: json['caregiver_id'] as String,
      title: json['title'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.task,
      ),
      description: json['description'] as String?,
      reminderTime: DateTime.parse(json['reminder_time'] as String).toLocal(),
      repeatRule: ReminderFrequency.values.firstWhere(
        (e) => e.name == json['repeat_rule'],
        orElse: () => ReminderFrequency.once,
      ),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == json['completion_status'],
        orElse: () => ReminderStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      completionHistory: (json['completion_history'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String).toLocal())
              .toList() ??
          [],
      isSnoozed: json['is_snoozed'] as bool? ?? false,
      snoozeDurationMinutes: json['snooze_duration_minutes'] as int?,
      lastSnoozedAt: json['last_snoozed_at'] != null
          ? DateTime.parse(json['last_snoozed_at'] as String).toLocal()
          : null,
      localAudioPath: json['localAudioPath'] as String?,
      notificationId: json['notificationId'] as int?,
      voiceAudioUrl: json['voiceAudioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'title': title,
      'type': type.name,
      'description': description,
      'reminder_time': reminderTime.toUtc().toIso8601String(),
      'repeat_rule': repeatRule.name,
      'completion_status': status.name,
      'created_at': createdAt.toUtc().toIso8601String(),
      'completion_history':
          completionHistory.map((e) => e.toUtc().toIso8601String()).toList(),
      'is_snoozed': isSnoozed,
      'snooze_duration_minutes': snoozeDurationMinutes,
      'last_snoozed_at': lastSnoozedAt?.toUtc().toIso8601String(),
      // localAudioPath, notificationId, voiceAudioUrl strictly local
    };
  }

  Reminder copyWith({
    String? id,
    String? patientId,
    String? caregiverId,
    String? title,
    ReminderType? type,
    String? description,
    DateTime? reminderTime,
    ReminderFrequency? repeatRule,
    ReminderStatus? status,
    DateTime? createdAt,
    List<DateTime>? completionHistory,
    bool? isSnoozed,
    int? snoozeDurationMinutes,
    DateTime? lastSnoozedAt,
    String? localAudioPath,
    int? notificationId,
    String? voiceAudioUrl,
  }) {
    return Reminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      caregiverId: caregiverId ?? this.caregiverId,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      reminderTime: reminderTime ?? this.reminderTime,
      repeatRule: repeatRule ?? this.repeatRule,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completionHistory: completionHistory ?? this.completionHistory,
      isSnoozed: isSnoozed ?? this.isSnoozed,
      snoozeDurationMinutes:
          snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      lastSnoozedAt: lastSnoozedAt ?? this.lastSnoozedAt,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      notificationId: notificationId ?? this.notificationId,
      voiceAudioUrl: voiceAudioUrl ?? this.voiceAudioUrl,
    );
  }

  // Convenience Getters & Aliases
  bool get isCompleted => status == ReminderStatus.completed;
  bool get hasVoiceNote => voiceAudioUrl != null || localAudioPath != null;
  DateTime get time => reminderTime;
  ReminderFrequency get frequency => repeatRule;
  int get snoozeCount => 0;
  List<DateTime> get missedLogs => [];
  DateTime? get completedAt =>
      completionHistory.isNotEmpty ? completionHistory.last : null;
}
