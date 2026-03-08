import 'package:hive_flutter/hive_flutter.dart';
import 'package:dementia_care_app/data/models/reminder.dart';

class HiveService {
  static const String remindersBoxName = 'reminders';

  /// Ensures the reminders box is opened and returned safely.
  static Future<Box<Reminder>> openReminderBox() async {
    if (!Hive.isBoxOpen(remindersBoxName)) {
      return await Hive.openBox<Reminder>(remindersBoxName);
    }
    return Hive.box<Reminder>(remindersBoxName);
  }
}
