import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sos_alert.dart';
import '../controllers/sos_controller.dart';
import '../screens/caregiver_alert_screen.dart';

class SafetyMonitor extends ConsumerStatefulWidget {
  final Widget child;

  const SafetyMonitor({super.key, required this.child});

  @override
  ConsumerState<SafetyMonitor> createState() => _SafetyMonitorState();
}

class _SafetyMonitorState extends ConsumerState<SafetyMonitor> {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final Set<String> _notifiedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Navigate to Alert Screen when tapped
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CaregiverAlertScreen()),
          );
        }
      },
    );
  }

  Future<void> _showNotification(SosAlert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Alerts',
      channelDescription: 'Notifications for SOS alerts',
      importance: Importance.max,
      priority: Priority.high,
      color: Colors.red,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBanner: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id: alert.id.hashCode,
      title: 'EMERGENCY ALERT',
      body: 'Patient needs help! Tap to track location.',
      notificationDetails: details,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to active alerts
    ref.listen(activeAlertsStreamProvider, (previous, next) {
      next.whenData((alerts) {
        for (final alert in alerts) {
          if (!_notifiedAlertIds.contains(alert.id)) {
            // New alert!
            _showNotification(alert);
            _notifiedAlertIds.add(alert.id);
          }
        }
      });
    });

    return widget.child;
  }
}
