import 'dart:io';

import 'package:flutter/material.dart'; // Add for Color
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/reminder.dart';
import '../../routes/app_router.dart';
import 'notification_permission_service.dart';

class ReminderNotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Centralized Permission Service
  final NotificationPermissionService _permissionService =
      NotificationPermissionService();

  /// Initialize the notification service and reschedule existing reminders
  Future<void> init() async {
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

    // 5. Reschedule all to ensure consistency (Now handled via Supabase Auth State)
    await _rescheduleAllReminders();
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

    AndroidScheduleMode scheduleMode = canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    if (!canScheduleExact) {
      print(
          'Exact Alarm Permission Missing. Fallback to INEXACT mode for ${reminder.title}.');
    }

    // 6. Attempt Scheduling
    try {
      // Attempt 1: Preferred Mode + Custom Sound
      await _scheduleNotification(
        id: notificationId,
        title: reminder.title,
        body: "It's time for your reminder",
        scheduledDate: scheduledDate,
        matchComponents: matchComponents,
        payload: reminder.id,
        useCustomSound: true,
        androidScheduleMode: scheduleMode,
      );
      print('✅ Scheduled notification for ${reminder.title} at $scheduledDate');
      print(
          'Scheduled (${scheduleMode.name}+Sound) for ${reminder.title} at $scheduledDate');
    } catch (e1) {
      print('Schedule attempt 1 failed (${scheduleMode.name}): $e1');

      // Fallback Strategy
      if (scheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        print('Trying fallback to INEXACT mode due to error.');
        scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
      }

      try {
        // Attempt 2: (Fallback Mode) + Default Sound (safer)
        await _scheduleNotification(
          id: notificationId,
          title: reminder.title,
          body: "It's time for your reminder",
          scheduledDate: scheduledDate,
          matchComponents: matchComponents,
          payload: reminder.id,
          useCustomSound: false, // Fallback to default sound
          androidScheduleMode: scheduleMode,
        );
        print(
            '✅ Scheduled notification for ${reminder.title} at $scheduledDate');
        print(
            'Scheduled (${scheduleMode.name}+DefaultSound) for ${reminder.title} at $scheduledDate');
      } catch (e2) {
        print('CRITICAL: All schedule attempts failed. Last error: $e2');
      }
    }
  }

  /// Internal helper to schedule with options
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents? matchComponents,
    required String payload,
    required bool useCustomSound,
    required AndroidScheduleMode androidScheduleMode,
  }) async {
    // Android Details
    final androidDetails = AndroidNotificationDetails(
      'reminder_channel',
      'Reminders',
      channelDescription: 'High priority alerts for reminders',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      styleInformation: const BigTextStyleInformation(''),
      sound: useCustomSound
          ? const RawResourceAndroidNotificationSound('gentle_tone')
          : null,
      visibility: NotificationVisibility.public,
    );

    // iOS Details
    final iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
      sound: useCustomSound ? 'gentle_tone.aiff' : null,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Using zonedSchedule for precise timing vs `show`
    await _notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: androidScheduleMode,
      matchDateTimeComponents: matchComponents,
      payload: payload,
      // Removed uiLocalNotificationDateInterpretation as it's deprecated/removed in v20
    );
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

  /// Fetch from Supabase and reschedule all suitable reminders
  Future<void> _rescheduleAllReminders() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      print('Rescheduling all reminders from Supabase...');
      await _notificationsPlugin.cancelAll();

      final response = await Supabase.instance.client
          .from('reminders')
          .select()
          .eq('patient_id', user.id);

      final List<dynamic> data = response;
      final now = DateTime.now();
      int scheduledCount = 0;

      for (var json in data) {
        final reminder = Reminder.fromJson(json);
        if (reminder.status == ReminderStatus.completed) continue;

        if (reminder.repeatRule == ReminderFrequency.once &&
            reminder.reminderTime
                .isBefore(now.subtract(const Duration(seconds: 30)))) {
          continue;
        }

        await scheduleReminder(reminder);
        scheduledCount++;
      }
      print('Rescheduled $scheduledCount valid reminders.');
    } catch (e) {
      print('Error rescheduling reminders: $e');
    }
  }

  // Kept for backward compatibility
  Future<void> requestPermissions() async {
    await _permissionService.ensureNotificationsReady();
  }
}
