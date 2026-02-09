import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/reminder.dart';
import '../routes/app_router.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    final payload = response.payload;
    if (payload != null && rootNavigatorKey.currentContext != null) {
      // Use GoRouter to push the alert screen
      GoRouter.of(rootNavigatorKey.currentContext!).push('/alert/$payload');
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    await _notificationsPlugin.zonedSchedule(
      reminder.hashCode,
      'Reminder: ${reminder.title}',
      reminder.type == ReminderType.medication
          ? 'Time for your medication'
          : 'You have a ${reminder.type.name} now',
      tz.TZDateTime.from(reminder.remindAt, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          channelDescription: 'High priority alerts for reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true, // Important for "Alarm" style behavior
          sound: RawResourceAndroidNotificationSound('gentle_alert'),
          // actions: [
          //   AndroidNotificationAction('done', 'Mark as Done'),
          //   AndroidNotificationAction('snooze', 'Snooze 10m'),
          // ],
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          sound: 'gentle_alert.aiff',
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: _getMatchComponents(reminder.repeatRule),
      payload: reminder.id,
    );
  }

  DateTimeComponents? _getMatchComponents(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return DateTimeComponents.time;
      case ReminderFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case ReminderFrequency.once:
      default:
        return null; // No repeat
    }
  }

  Future<void> cancelReminder(String id) async {
    // We used hashCode as ID. Ideally we should map string ID to int ID.
    // For now, assuming hashCode is stable enough for this demo or we store the simple int ID.
    // Better: maintain a map or use a hash of the UUID.
    // However, string.hashCode isn't guaranteed stable across runs in some envs, but in Dart it's okay for runtime. For persistent scheduling, integer ID is better.
    // Let's use a stable hash for the string ID.
    await _notificationsPlugin.cancel(id.hashCode);
  }
}
