import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 0)
enum ReminderType {
  @HiveField(0)
  medication,
  @HiveField(1)
  appointment,
  @HiveField(2)
  task,
}

@HiveType(typeId: 1)
enum ReminderFrequency {
  @HiveField(0)
  once,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  custom,
}

@HiveType(typeId: 2)
enum ReminderStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
  @HiveField(2)
  missed,
}

@HiveType(typeId: 3)
class Reminder {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String patientId;
  @HiveField(2)
  final String caregiverId;
  @HiveField(3)
  final String title;
  @HiveField(4)
  final ReminderType type;
  @HiveField(5)
  final String? description;
  @HiveField(6)
  final DateTime reminderTime;
  @HiveField(7)
  final ReminderFrequency repeatRule;
  @HiveField(8)
  final ReminderStatus status;
  @HiveField(9)
  final DateTime createdAt;
  @HiveField(10)
  final List<DateTime> completionHistory;
  @HiveField(11)
  final bool isSnoozed;
  @HiveField(12)
  final int? snoozeDurationMinutes;
  @HiveField(13)
  final DateTime? lastSnoozedAt;

  // Local only properties (not sent to Supabase)
  @HiveField(14)
  final String? localAudioPath;
  @HiveField(15)
  final int? notificationId;

  // Keeping this for compatibility in UI but it's local only since it's not in schema
  @HiveField(16)
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
      voiceAudioUrl: json['voice_audio_url'] as String?,
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
      'voice_audio_url': voiceAudioUrl,
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

  /// True when any audio source is available (local file or remote URL).
  bool get hasVoiceNote =>
      (localAudioPath != null && localAudioPath!.isNotEmpty) ||
      (voiceAudioUrl != null && voiceAudioUrl!.isNotEmpty);

  /// Returns the best audio source: local file first (offline-first), then remote URL.
  String? get audioSource =>
      (localAudioPath != null && localAudioPath!.isNotEmpty)
          ? localAudioPath
          : voiceAudioUrl;

  DateTime get time => reminderTime;
  ReminderFrequency get frequency => repeatRule;
  int get snoozeCount => 0;
  List<DateTime> get missedLogs => [];
  DateTime? get completedAt =>
      completionHistory.isNotEmpty ? completionHistory.last : null;
}
