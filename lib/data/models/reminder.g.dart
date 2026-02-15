// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 0;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as String,
      patientId: fields[1] as String,
      title: fields[2] as String,
      type: fields[3] as ReminderType,
      remindAt: fields[5] as DateTime,
      createdAt: fields[11] as DateTime,
      description: fields[4] as String?,
      repeatRule: fields[6] as ReminderFrequency,
      createdBy: fields[7] as String?,
      status: fields[8] as ReminderStatus,
      voiceAudioUrl: fields[9] as String?,
      localAudioPath: fields[10] as String?,
      isSynced: fields[12] as bool,
      completionHistory: (fields[13] as List).cast<DateTime>(),
      isSnoozed: fields[14] as bool,
      snoozeDurationMinutes: fields[15] as int?,
      lastSnoozedAt: fields[16] as DateTime?,
      notificationId: fields[17] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.remindAt)
      ..writeByte(6)
      ..write(obj.repeatRule)
      ..writeByte(7)
      ..write(obj.createdBy)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.voiceAudioUrl)
      ..writeByte(10)
      ..write(obj.localAudioPath)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.isSynced)
      ..writeByte(13)
      ..write(obj.completionHistory)
      ..writeByte(14)
      ..write(obj.isSnoozed)
      ..writeByte(15)
      ..write(obj.snoozeDurationMinutes)
      ..writeByte(16)
      ..write(obj.lastSnoozedAt)
      ..writeByte(17)
      ..write(obj.notificationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderTypeAdapter extends TypeAdapter<ReminderType> {
  @override
  final int typeId = 1;

  @override
  ReminderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderType.medication;
      case 1:
        return ReminderType.appointment;
      case 2:
        return ReminderType.task;
      default:
        return ReminderType.medication;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderType obj) {
    switch (obj) {
      case ReminderType.medication:
        writer.writeByte(0);
        break;
      case ReminderType.appointment:
        writer.writeByte(1);
        break;
      case ReminderType.task:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderFrequencyAdapter extends TypeAdapter<ReminderFrequency> {
  @override
  final int typeId = 2;

  @override
  ReminderFrequency read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderFrequency.once;
      case 1:
        return ReminderFrequency.daily;
      case 2:
        return ReminderFrequency.weekly;
      case 3:
        return ReminderFrequency.custom;
      default:
        return ReminderFrequency.once;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderFrequency obj) {
    switch (obj) {
      case ReminderFrequency.once:
        writer.writeByte(0);
        break;
      case ReminderFrequency.daily:
        writer.writeByte(1);
        break;
      case ReminderFrequency.weekly:
        writer.writeByte(2);
        break;
      case ReminderFrequency.custom:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderFrequencyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderStatusAdapter extends TypeAdapter<ReminderStatus> {
  @override
  final int typeId = 3;

  @override
  ReminderStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderStatus.pending;
      case 1:
        return ReminderStatus.completed;
      case 2:
        return ReminderStatus.missed;
      default:
        return ReminderStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderStatus obj) {
    switch (obj) {
      case ReminderStatus.pending:
        writer.writeByte(0);
        break;
      case ReminderStatus.completed:
        writer.writeByte(1);
        break;
      case ReminderStatus.missed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reminder _$ReminderFromJson(Map<String, dynamic> json) => Reminder(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      title: json['title'] as String,
      type: $enumDecode(_$ReminderTypeEnumMap, json['type']),
      remindAt: DateTime.parse(json['remind_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      description: json['description'] as String?,
      repeatRule: $enumDecodeNullable(
              _$ReminderFrequencyEnumMap, json['repeat_rule']) ??
          ReminderFrequency.once,
      createdBy: json['created_by'] as String?,
      status: $enumDecodeNullable(
              _$ReminderStatusEnumMap, json['completion_status']) ??
          ReminderStatus.pending,
      voiceAudioUrl: json['voice_audio_url'] as String?,
      completionHistory: (json['completion_history'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
      isSnoozed: json['is_snoozed'] as bool? ?? false,
      snoozeDurationMinutes: (json['snooze_duration_minutes'] as num?)?.toInt(),
      lastSnoozedAt: json['last_snoozed_at'] == null
          ? null
          : DateTime.parse(json['last_snoozed_at'] as String),
    );

Map<String, dynamic> _$ReminderToJson(Reminder instance) => <String, dynamic>{
      'id': instance.id,
      'patient_id': instance.patientId,
      'title': instance.title,
      'type': _$ReminderTypeEnumMap[instance.type]!,
      'description': instance.description,
      'remind_at': instance.remindAt.toIso8601String(),
      'repeat_rule': _$ReminderFrequencyEnumMap[instance.repeatRule]!,
      'created_by': instance.createdBy,
      'completion_status': _$ReminderStatusEnumMap[instance.status]!,
      'voice_audio_url': instance.voiceAudioUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'completion_history':
          instance.completionHistory.map((e) => e.toIso8601String()).toList(),
      'is_snoozed': instance.isSnoozed,
      'snooze_duration_minutes': instance.snoozeDurationMinutes,
      'last_snoozed_at': instance.lastSnoozedAt?.toIso8601String(),
    };

const _$ReminderTypeEnumMap = {
  ReminderType.medication: 'medication',
  ReminderType.appointment: 'appointment',
  ReminderType.task: 'task',
};

const _$ReminderFrequencyEnumMap = {
  ReminderFrequency.once: 'once',
  ReminderFrequency.daily: 'daily',
  ReminderFrequency.weekly: 'weekly',
  ReminderFrequency.custom: 'custom',
};

const _$ReminderStatusEnumMap = {
  ReminderStatus.pending: 'pending',
  ReminderStatus.completed: 'completed',
  ReminderStatus.missed: 'missed',
};
