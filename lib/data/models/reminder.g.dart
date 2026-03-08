// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderAdapter extends TypeAdapter<Reminder> {
  @override
  final int typeId = 3;

  @override
  Reminder read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Reminder(
      id: fields[0] as String,
      patientId: fields[1] as String,
      caregiverId: fields[2] as String,
      title: fields[3] as String,
      type: fields[4] as ReminderType,
      reminderTime: fields[6] as DateTime,
      createdAt: fields[9] as DateTime,
      description: fields[5] as String?,
      repeatRule: fields[7] as ReminderFrequency,
      status: fields[8] as ReminderStatus,
      completionHistory: (fields[10] as List).cast<DateTime>(),
      isSnoozed: fields[11] as bool,
      snoozeDurationMinutes: fields[12] as int?,
      lastSnoozedAt: fields[13] as DateTime?,
      localAudioPath: fields[14] as String?,
      notificationId: fields[15] as int?,
      voiceAudioUrl: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Reminder obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientId)
      ..writeByte(2)
      ..write(obj.caregiverId)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.reminderTime)
      ..writeByte(7)
      ..write(obj.repeatRule)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completionHistory)
      ..writeByte(11)
      ..write(obj.isSnoozed)
      ..writeByte(12)
      ..write(obj.snoozeDurationMinutes)
      ..writeByte(13)
      ..write(obj.lastSnoozedAt)
      ..writeByte(14)
      ..write(obj.localAudioPath)
      ..writeByte(15)
      ..write(obj.notificationId)
      ..writeByte(16)
      ..write(obj.voiceAudioUrl);
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
  final int typeId = 0;

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
  final int typeId = 1;

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
  final int typeId = 2;

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
