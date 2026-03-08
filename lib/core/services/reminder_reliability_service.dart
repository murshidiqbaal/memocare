import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dementia_care_app/core/services/battery_optimization_service.dart';

class ReminderReliabilityService {
  final BatteryOptimizationService _batteryService =
      BatteryOptimizationService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Comprehensive check for factors that might prevent notifications from firing accurately.
  Future<Map<String, bool>> checkReliability() async {
    final status = <String, bool>{};

    if (Platform.isAndroid) {
      // 1. Notification Permission
      status['notifications'] = await Permission.notification.isGranted;

      // 2. Exact Alarm Permission (Android 12+)
      status['exact_alarm'] = await Permission.scheduleExactAlarm.isGranted;

      // 3. Battery Optimization
      status['battery_optimized'] =
          await _batteryService.isBatteryOptimizationEnabled();

      // 4. Notification Channel Check
      status['channel_exists'] = await _checkChannelExists('reminder_channel');

      _logStatus(status);
    } else {
      status['notifications'] = await Permission.notification.isGranted;
    }

    return status;
  }

  Future<bool> _checkChannelExists(String channelId) async {
    try {
      final channels = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.getNotificationChannels();
      return channels?.any((c) => c.id == channelId) ?? false;
    } catch (e) {
      return false;
    }
  }

  void _logStatus(Map<String, bool> status) {
    if (status['battery_optimized'] == true) {
      print('CRITICAL: App is BATTERY OPTIMIZED. Reminders may be delayed.');
    }
    if (status['exact_alarm'] == false) {
      print(
          'WARNING: Exact alarm permission missing. Notifications might not be precise.');
    }
    if (status['notifications'] == false) {
      print('ERROR: Notification permission is DISABLED.');
    }
  }
}
