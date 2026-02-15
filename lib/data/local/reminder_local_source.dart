import 'package:dementia_care_app/data/models/reminder.dart';
import 'package:hive/hive.dart';

class ReminderLocalSource {
  static const String boxName = 'reminders_box';

  /// Open box safely
  Future<Box<Reminder>> _openBox() async {
    return await Hive.openBox<Reminder>(boxName);
  }

  /// Get reminders for a specific patient
  Future<List<Reminder>> getRemindersByPatient(String patientId) async {
    final box = await _openBox();

    return box.values.where((r) => r.patientId == patientId).toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
  }

  /// Save or update reminder
  Future<void> saveReminder(Reminder reminder) async {
    final box = await _openBox();
    await box.put(reminder.id, reminder);
  }

  /// Delete reminder
  Future<void> deleteReminder(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }
}
