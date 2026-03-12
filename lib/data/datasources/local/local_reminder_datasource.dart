import 'package:hive_flutter/hive_flutter.dart';
import 'package:memocare/core/services/hive_service.dart';
import 'package:memocare/data/models/reminder.dart';

class LocalReminderDatasource {
  Future<Box<Reminder>> get _box async => HiveService.openReminderBox();

  /// Save or update a reminder locally.
  Future<void> saveReminder(Reminder reminder) async {
    final box = await _box;
    await box.put(reminder.id, reminder);
  }

  /// Save multiple reminders.
  Future<void> saveAllReminders(List<Reminder> reminders) async {
    final box = await _box;
    final Map<String, Reminder> entries = {for (var r in reminders) r.id: r};
    await box.putAll(entries);
  }

  /// Get all reminders stored locally.
  Future<List<Reminder>> getAllReminders() async {
    final box = await _box;
    return box.values.toList();
  }

  /// Delete a reminder locally.
  Future<void> deleteReminder(String id) async {
    final box = await _box;
    await box.delete(id);
  }

  /// Clear all local reminders.
  Future<void> clearAll() async {
    final box = await _box;
    await box.clear();
  }
}
