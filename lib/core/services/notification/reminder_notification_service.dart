import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart'; // Add for Color
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:memocare/data/models/reminder.dart';
import 'package:memocare/router/app_router.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../../data/datasources/local/local_reminder_datasource.dart';
import 'notification_permission_service.dart';

class ReminderNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Centralized Permission Service
  final NotificationPermissionService _permissionService =
      NotificationPermissionService();

  /// Initialize the notification service and reschedule existing reminders
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Initialize Timezones
    tz.initializeTimeZones();
    try {
      final dynamic potentialName = await FlutterTimezone.getLocalTimezone();
      final String timeZoneName = potentialName.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      print('Initialized Timezone: $timeZoneName');
    } catch (e) {
      print(
          'Failed to get local timezone: $e. Using generic local (UTC/Device Default).');
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

    // 3. Initialize Plugin
    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // 4. Ensure Permissions (Android 13+, Exact Alarm, Battery Optimization)
    await _permissionService.ensureNotificationsReady();

    // 5. Create Notification Channels
    await _createNotificationChannels();

    // 6. Reschedule all to ensure consistency
    await _rescheduleAllReminders();

    _isInitialized = true;
  }

  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin == null) return;

    // Reminder Channel
    const reminderChannel = AndroidNotificationChannel(
      'reminder_channel',
      'Reminders',
      description: 'Standard medicine and task reminders',
      importance: Importance.high,
      playSound: true,
    );

    // Alarm Channel
    const alarmChannel = AndroidNotificationChannel(
      'reminder_alarm_channel',
      'Reminder Alarm',
      description: 'Medicine reminder alarms',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('reminder_alarm'),
      enableVibration: true,
    );

    await androidPlugin.createNotificationChannel(reminderChannel);
    await androidPlugin.createNotificationChannel(alarmChannel);
    print('✅ Notification channels created');
  }

  /// Handle notification tap to navigate to authorized alert screen
  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null && rootNavigatorKey.currentContext != null) {
      GoRouter.of(rootNavigatorKey.currentContext!)
          .push('/alert/${response.payload}');
    }
  }

  /// Schedule a specific reminder
  Future<void> scheduleReminder(Reminder reminder) async {
    if (!_isInitialized) {
      print('WARNING: Cannot schedule reminder, service not initialized.');
      return;
    }

    // 1. Determine ID
    final int notificationId = reminder.notificationId ?? reminder.id.hashCode;

    // 2. Calculate the next valid schedule time
    tz.TZDateTime scheduledDate = _nextInstanceOf(reminder);
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    // 3. Handle Past/Near-Past Scheduling (5-second tolerance)
    if (scheduledDate.isBefore(now)) {
      if (scheduledDate.isAfter(now.subtract(const Duration(seconds: 5)))) {
        scheduledDate = now.add(const Duration(seconds: 5));
      } else {
        print('Skipping past reminder: ${reminder.title} at $scheduledDate');
        return;
      }
    }

    // 4. Repeat interval
    DateTimeComponents? matchComponents;
    if (reminder.repeatRule == ReminderFrequency.daily) {
      matchComponents = DateTimeComponents.time;
    } else if (reminder.repeatRule == ReminderFrequency.weekly) {
      matchComponents = DateTimeComponents.dayOfWeekAndTime;
    }

    // 5. Determine Safe Scheduling Mode
    bool canScheduleExact = true;
    if (Platform.isAndroid) {
      canScheduleExact = await _permissionService.isExactAlarmGranted;
    }

    final scheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    if (!canScheduleExact) {
      print(
          'Exact Alarm Permission Missing. Fallback to INEXACT mode for ${reminder.title}.');
    }

    // 6. Attempt Scheduling
    try {
      if (reminder.alarmEnabled) {
        // High Priority Alarm
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: reminder.title,
          body: "Time for your medication: ${reminder.title}",
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_alarm_channel',
              'Reminder Alarm',
              channelDescription: 'Emergency/Medical Alarms',
              importance: Importance.max,
              priority: Priority.max,
              fullScreenIntent: true,
              category: AndroidNotificationCategory.alarm,
              playSound: true,
              sound:
                  const RawResourceAndroidNotificationSound('reminder_alarm'),
              vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
              enableVibration: true,
              visibility: NotificationVisibility.public,
            ),
            iOS: const DarwinNotificationDetails(
              presentSound: true,
              presentAlert: true,
              presentBadge: true,
              sound: 'alarm.mp3',
              interruptionLevel: InterruptionLevel.critical,
            ),
          ),
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: matchComponents,
          payload: reminder.id,
        );
      } else {
        // Normal Notification
        await _notificationsPlugin.zonedSchedule(
          id: notificationId,
          title: reminder.title,
          body: "It's time for your reminder",
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'reminder_channel',
              'Reminders',
              channelDescription: 'Standard reminders',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: DarwinNotificationDetails(
              presentSound: true,
              presentAlert: true,
              presentBadge: true,
            ),
          ),
          androidScheduleMode: scheduleMode,
          matchDateTimeComponents: matchComponents,
          payload: reminder.id,
        );
      }
      print(
          '✅ Scheduled ${reminder.alarmEnabled ? 'ALARM' : 'Notification'} for ${reminder.title} at $scheduledDate');
    } catch (e) {
      print('CRITICAL: All schedule attempts failed. Last error: $e');
    }
  }

  /// Calculate next instance for repeating reminders if start time is past
  tz.TZDateTime _nextInstanceOf(Reminder reminder) {
    // ... (Same logic as before)
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

  /// Cancel a specific reminder
  Future<void> cancelReminder(Reminder reminder) async {
    final int id = reminder.notificationId ?? reminder.id.hashCode;
    await _notificationsPlugin.cancel(id: id); // Corrected Named Arg
    print('Cancelled notification (ID: $id) for ${reminder.title}');
  }

  // Overload for cancelling by ID string (legacy/fallback)
  Future<void> cancelReminderById(String reminderId) async {
    await _notificationsPlugin.cancel(id: reminderId.hashCode);
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
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
      category: AndroidNotificationCategory.alarm,
      color: Color(0xFFFF0000), // Red
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

  /// Cancel all reminders
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Fetch from Local Storage and reschedule all suitable reminders
  Future<void> _rescheduleAllReminders() async {
    try {
      print('Rescheduling all reminders from Local Storage...');
      await _notificationsPlugin.cancelAll();

      final localDatasource = LocalReminderDatasource();
      final reminders = await localDatasource.getAllReminders();

      final now = DateTime.now();
      int scheduledCount = 0;

      for (var reminder in reminders) {
        if (reminder.status == ReminderStatus.completed) continue;

        if (reminder.repeatRule == ReminderFrequency.once &&
            reminder.reminderTime
                .isBefore(now.subtract(const Duration(seconds: 30)))) {
          continue;
        }

        await scheduleReminder(reminder);
        scheduledCount++;
      }
      print('Rescheduled $scheduledCount valid reminders from Hive.');
    } catch (e) {
      print('Error rescheduling reminders: $e');
    }
  }

  // Kept for backward compatibility
  Future<void> requestPermissions() async {
    await _permissionService.ensureNotificationsReady();
  }
}
