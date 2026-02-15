import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'reminder.g.dart';

@HiveType(typeId: 1)
enum ReminderType {
  @HiveField(0)
  medication,
  @HiveField(1)
  appointment,
  @HiveField(2)
  task,
}

@HiveType(typeId: 2)
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

@HiveType(typeId: 3)
enum ReminderStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  completed,
  @HiveField(2)
  missed,
}

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: 0)
class Reminder extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'patient_id')
  final String patientId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final ReminderType type;

  @HiveField(4)
  final String? description;

  @HiveField(5)
  @JsonKey(name: 'remind_at')
  final DateTime remindAt;

  @HiveField(6)
  @JsonKey(name: 'repeat_rule')
  final ReminderFrequency repeatRule;

  @HiveField(7)
  @JsonKey(name: 'created_by')
  final String? createdBy;

  @HiveField(8)
  @JsonKey(name: 'completion_status')
  final ReminderStatus status;

  @HiveField(9)
  @JsonKey(name: 'voice_audio_url')
  final String? voiceAudioUrl;

  @HiveField(10)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? localAudioPath;

  @HiveField(11)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(12)
  @JsonKey(includeFromJson: false, includeToJson: false)
  final bool isSynced;

  @HiveField(13)
  @JsonKey(name: 'completion_history')
  final List<DateTime> completionHistory;

  @HiveField(14)
  @JsonKey(name: 'is_snoozed')
  final bool isSnoozed;

  @HiveField(15)
  @JsonKey(name: 'snooze_duration_minutes')
  final int? snoozeDurationMinutes;

  @HiveField(16)
  @JsonKey(name: 'last_snoozed_at')
  final DateTime? lastSnoozedAt;

  @HiveField(17)
  @JsonKey(
      name: 'notification_id', includeFromJson: false, includeToJson: false)
  final int? notificationId;

  Reminder({
    required this.id,
    required this.patientId,
    required this.title,
    required this.type,
    required this.remindAt,
    required this.createdAt,
    this.description,
    this.repeatRule = ReminderFrequency.once,
    this.createdBy,
    this.status = ReminderStatus.pending,
    this.voiceAudioUrl,
    this.localAudioPath,
    this.isSynced = true,
    this.completionHistory = const [],
    this.isSnoozed = false,
    this.snoozeDurationMinutes,
    this.lastSnoozedAt,
    this.notificationId,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) =>
      _$ReminderFromJson(json);

  Map<String, dynamic> toJson() => _$ReminderToJson(this);

  Reminder copyWith({
    String? id,
    String? patientId,
    String? title,
    ReminderType? type,
    String? description,
    DateTime? remindAt,
    ReminderFrequency? repeatRule,
    String? createdBy,
    ReminderStatus? status,
    String? voiceAudioUrl,
    String? localAudioPath,
    DateTime? createdAt,
    bool? isSynced,
    List<DateTime>? completionHistory,
    bool? isSnoozed,
    int? snoozeDurationMinutes,
    DateTime? lastSnoozedAt,
    int? notificationId,
  }) {
    return Reminder(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      title: title ?? this.title,
      type: type ?? this.type,
      description: description ?? this.description,
      remindAt: remindAt ?? this.remindAt,
      repeatRule: repeatRule ?? this.repeatRule,
      createdBy: createdBy ?? this.createdBy,
      status: status ?? this.status,
      voiceAudioUrl: voiceAudioUrl ?? this.voiceAudioUrl,
      localAudioPath: localAudioPath ?? this.localAudioPath,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
      completionHistory: completionHistory ?? this.completionHistory,
      isSnoozed: isSnoozed ?? this.isSnoozed,
      snoozeDurationMinutes:
          snoozeDurationMinutes ?? this.snoozeDurationMinutes,
      lastSnoozedAt: lastSnoozedAt ?? this.lastSnoozedAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  // Convenience Getters & Aliases
  bool get isCompleted => status == ReminderStatus.completed;
  bool get hasVoiceNote => voiceAudioUrl != null || localAudioPath != null;
  DateTime get time => remindAt;
  ReminderFrequency get frequency => repeatRule;
  int get snoozeCount => 0;
  List<DateTime> get missedLogs => [];
  DateTime? get completedAt =>
      completionHistory.isNotEmpty ? completionHistory.last : null;
}
