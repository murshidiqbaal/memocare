import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');

  // Show notification even when app is terminated
  if (message.notification != null) {
    final FlutterLocalNotificationsPlugin localNotifications =
        FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await localNotifications.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );

    await localNotifications.show(
      id: message.hashCode,
      title: message.notification!.title,
      body: message.notification!.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel',
          'Emergency Alerts',
          channelDescription: 'Critical SOS and emergency notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }
}

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase;

  FCMService(this._supabase);

  /// Initialize FCM and request permissions
  Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      print('FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        String? token = await _messaging.getToken();
        if (token != null) {
          print('FCM Token: $token');
          await _saveFCMToken(token);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveFCMToken);

        // Set up message handlers
        await _setupMessageHandlers();

        // Set up background handler
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);
      } else {
        print('FCM permission denied');
      }
    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  /// Save FCM token to Supabase
  Future<void> _saveFCMToken(String token) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('No user logged in, cannot save FCM token');
        return;
      }

      // Check if user is a caregiver
      final caregiverResponse = await _supabase
          .from('caregivers')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (caregiverResponse != null) {
        // Update caregiver FCM token
        await _supabase
            .from('caregivers')
            .update({'fcm_token': token}).eq('user_id', userId);
        print('FCM token saved for caregiver');
      } else {
        // Check if user is a patient
        final patientResponse = await _supabase
            .from('patients')
            .select('id')
            .eq('user_id', userId)
            .maybeSingle();

        if (patientResponse != null) {
          // Update patient FCM token (optional, for future features)
          await _supabase
              .from('patients')
              .update({'fcm_token': token}).eq('user_id', userId);
          print('FCM token saved for patient');
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Set up foreground and background message handlers
  Future<void> _setupMessageHandlers() async {
    // Initialize local notifications for Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      onDidReceiveNotificationResponse: _onNotificationTapped,
      settings: const InitializationSettings(android: androidSettings),
    );

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emergency_channel',
      'Emergency Alerts',
      description: 'Critical SOS and emergency notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.messageId}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }

      // Handle data payload
      if (message.data.isNotEmpty) {
        _handleMessageData(message.data);
      }
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.messageId}');
      _handleMessageData(message.data);
    });

    // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from notification: ${initialMessage.messageId}');
      _handleMessageData(initialMessage.data);
    }
  }

  /// Show local notification for foreground messages
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'emergency_channel',
          'Emergency Alerts',
          channelDescription: 'Critical SOS and emergency notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF0000), // Red for emergency
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    // TODO: Navigate to appropriate screen based on payload
    // This will be implemented with navigation service
  }

  /// Handle message data payload
  void _handleMessageData(Map<String, dynamic> data) {
    print('Handling message data: $data');

    final type = data['type'];
    switch (type) {
      case 'sos_alert':
        _handleSOSAlert(data);
        break;
      case 'reminder':
        _handleReminderNotification(data);
        break;
      case 'location_alert':
        _handleLocationAlert(data);
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  /// Handle SOS alert notification
  void _handleSOSAlert(Map<String, dynamic> data) {
    print('SOS Alert received: $data');
    // TODO: Navigate to emergency alert screen
    // TODO: Show high-priority dialog
  }

  /// Handle reminder notification
  void _handleReminderNotification(Map<String, dynamic> data) {
    print('Reminder notification received: $data');
    // TODO: Navigate to reminder details
  }

  /// Handle location alert (geofence breach)
  void _handleLocationAlert(Map<String, dynamic> data) {
    print('Location alert received: $data');
    // TODO: Navigate to live tracking screen
  }

  /// Delete FCM token on logout
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }
}
