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

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
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
      id: reminder.hashCode, // Named 'id'
      title: 'Reminder: ${reminder.title}', // Named 'title'
      body: reminder.type == ReminderType.medication
          ? 'Time for your medication'
          : 'You have a ${reminder.type.name} now', // Named 'body'
      scheduledDate: tz.TZDateTime.from(
          reminder.remindAt, tz.local), // Named 'scheduledDate'
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder_channel',
          'Reminders',
          channelDescription: 'High priority alerts for reminders',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentSound: true,
          presentAlert: true,
          presentBadge: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
    // Using hashCode as ID as per implementation
    await _notificationsPlugin.cancel(id: id.hashCode);
  }
}
