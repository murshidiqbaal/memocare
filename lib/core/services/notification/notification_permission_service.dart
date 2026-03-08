import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPermissionService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Comprehensive check and request flow.
  /// Returns [true] if basic notification capability is ready (even if fallback needed).
  /// Returns [false] only if notifications are completely blocked (e.g. POST_NOTIFICATIONS denied).
  Future<bool> ensureNotificationsReady() async {
    if (!Platform.isAndroid) return true; // iOS flow differs

    print('--- NotificationPermissionService: Starting Reliability Check ---');
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final int sdkInt = androidInfo.version.sdkInt;
      print('Device SDK: $sdkInt (${androidInfo.version.release})');

      // 1. Notification Permission (Android 13+ / SDK 33+)
      if (sdkInt >= 33) {
        final granted = await _requestNotificationPermission();
        if (!granted) {
          print('CRITICAL: Notification permission DENIED. Cannot schedule.');
          return false;
        }
        print('Notification permission: GRANTED');
      }

      // 2. Exact Alarm Permission (Android 12+ / SDK 31+)
      if (sdkInt >= 31) {
        final exact = await isExactAlarmGranted;
        if (!exact) {
          print(
              'WARNING: Exact Alarm permission MISSING. Will request or use fallback.');
          // Try to request
          await _requestExactAlarmPermission();
        } else {
          print('Exact Alarm permission: GRANTED');
        }
      }

      // 3. Battery Optimization (Critical for reliability)
      final isIgnoring = await isIgnoringBatteryOptimizations();
      if (!isIgnoring) {
        print(
            'CRITICAL: App is BATTERY OPTIMIZED. Alarms may be delayed or blocked by OEM.');
      } else {
        print('Battery Optimization: DISABLED (Reliable).');
      }

      print('--- NotificationPermissionService: Check Complete ---');
      return true;
    } catch (e) {
      print('Error in NotificationPermissionService: $e');
      return true; // Fail safe to allow attempt
    }
  }

  // --- Internal Helpers ---

  Future<bool> _requestNotificationPermission() async {
    if (await Permission.notification.isGranted) return true;
    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<void> _requestExactAlarmPermission() async {
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // --- Public API for UI/Service ---

  Future<bool> get isExactAlarmGranted async {
    // Check if permitted
    // Note: On Android < 12, exact alarms are granted by default usually.
    // But permission_handler check is safe.
    if (Platform.isAndroid) {
      // Only relevant for Android 12+ (SDK 31+)
      // But permission_handler handles this check gracefully.
      return await Permission.scheduleExactAlarm.isGranted;
    }
    return true;
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    return await Permission.ignoreBatteryOptimizations.isGranted;
  }

  Future<void> requestIgnoreBatteryOptimizations() async {
    if (Platform.isAndroid) {
      final status = await Permission.ignoreBatteryOptimizations.request();
      print('Requested Battery Optimization Ignore: $status');
    }
  }
}
