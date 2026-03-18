import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../data/models/reminder.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final dynamic potentialName = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = potentialName.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Initialized Timezone: $timeZoneName');
    } catch (e) {
      debugPrint('NotificationService: Failed to get local timezone: $e');
    }

    // 2. Initialize Settings
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
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );

    // 3. Create the reminder channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminder Notifications',
      description: 'Notifications for medicine and task reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(channel);
    }
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.alarmEnabled || reminder.status == ReminderStatus.completed) {
      await cancelReminder(reminder);
      return;
    }

    final scheduledDate = _nextInstanceOf(reminder);
    final now = tz.TZDateTime.now(tz.local);

    // Skip if in the past
    if (scheduledDate.isBefore(now)) {
      debugPrint(
          'NotificationService: Skipping past reminder: ${reminder.title}');
      return;
    }

    try {
      await _notificationsPlugin.zonedSchedule(
        id: reminder.notificationId ?? reminder.id.hashCode,
        title: 'Medicine Reminder',
        body: 'Time for your medication: ${reminder.title}',
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            reminder.alarmEnabled
                ? 'reminder_alarm_channel_v2'
                : 'reminder_channel',
            reminder.alarmEnabled ? 'Reminder Alarm' : 'Reminders',
            channelDescription: reminder.alarmEnabled
                ? 'Medicine reminder alarms'
                : 'Standard medicine and task reminders',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            fullScreenIntent: reminder.alarmEnabled,
            category: reminder.alarmEnabled
                ? AndroidNotificationCategory.alarm
                : null,
            playSound: true,
            enableVibration: true,
            sound: reminder.alarmEnabled
                ? const RawResourceAndroidNotificationSound('alarm')
                : null,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: reminder.alarmEnabled ? 'alarm.mp3' : null,
            interruptionLevel: InterruptionLevel.critical,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: _getMatchComponents(reminder.repeatRule),
        payload: reminder.id,
      );
      debugPrint(
          'NotificationService: Scheduled ${reminder.title} for $scheduledDate');
    } catch (e) {
      debugPrint('NotificationService: Error scheduling ${reminder.title}: $e');
    }
  }

  tz.TZDateTime _nextInstanceOf(Reminder reminder) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime.from(reminder.reminderTime, tz.local);

    if (scheduledDate.isBefore(now)) {
      if (reminder.repeatRule == ReminderFrequency.daily) {
        final todayInstance = tz.TZDateTime(tz.local, now.year, now.month,
            now.day, scheduledDate.hour, scheduledDate.minute);
        if (todayInstance.isBefore(now)) {
          scheduledDate = todayInstance.add(const Duration(days: 1));
        } else {
          scheduledDate = todayInstance;
        }
      } else if (reminder.repeatRule == ReminderFrequency.weekly) {
        while (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 7));
        }
      }
    }
    return scheduledDate;
  }

  DateTimeComponents? _getMatchComponents(ReminderFrequency frequency) {
    switch (frequency) {
      case ReminderFrequency.daily:
        return DateTimeComponents.time;
      case ReminderFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case ReminderFrequency.once:
      default:
        return null;
    }
  }

  Future<void> cancelReminder(Reminder reminder) async {
    final int id = reminder.notificationId ?? reminder.id.hashCode;
    await _notificationsPlugin.cancel(id: id);
    debugPrint(
        'NotificationService: Cancelled notification for: ${reminder.title}');
  }

  Future<void> cancelReminderById(String id) async {
    await _notificationsPlugin.cancel(id: id.hashCode);
    debugPrint('NotificationService: Cancelled notification for ID: $id');
  }

  Future<void> cancelNotification(String id) async {
    await cancelReminderById(id);
  }

  Future<void> showEmergencyNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Critical alerts for SOS and safety events',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      color: const Color(0xFFFF0000), // Red
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: 99999,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
