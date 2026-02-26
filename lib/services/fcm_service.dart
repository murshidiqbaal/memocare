import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// STEP 1: Background Message Handler — must be a TOP-LEVEL function
//
// Called by Firebase when the app is TERMINATED or BACKGROUND.
// Runs in a separate Dart Isolate — cannot use Flutter UI or Riverpod.
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final localNotifications = FlutterLocalNotificationsPlugin();

  await localNotifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  final channel = _channelForType(message.data['type']);
  final id = _stableNotificationId(message);

  if (message.notification != null) {
    await localNotifications.show(
      id: id,
      title: message.notification!.title ?? 'MemoCare',
      body: message.notification!.body ?? '',
      notificationDetails:
          NotificationDetails(android: _androidDetails(channel)),
      payload: _buildPayload(message.data),
    );
  } else if (message.data.isNotEmpty) {
    // Data-only FCM message
    final title = message.data['title'] as String? ?? 'MemoCare';
    final body = message.data['body'] as String? ?? '';
    if (body.isNotEmpty) {
      await localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails:
            NotificationDetails(android: _androidDetails(channel)),
        payload: _buildPayload(message.data),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Background local notification tap (top-level, required by v20+)
// ─────────────────────────────────────────────────────────────────────────────
@pragma('vm:entry-point')
void onBackgroundNotificationTapped(NotificationResponse response) {
  // Routing is handled by onMessageOpenedApp / getInitialMessage.
  debugPrint('[FCM] Background local tap: ${response.payload}');
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification Channels
// ─────────────────────────────────────────────────────────────────────────────

const _reminderChannel = AndroidNotificationChannel(
  'reminder_channel',
  'Reminders',
  description: 'Medication and appointment reminders',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  sound: RawResourceAndroidNotificationSound('gentle_tone'),
);

const _emergencyChannel = AndroidNotificationChannel(
  'emergency_channel',
  'Emergency Alerts',
  description: 'Critical SOS and safety notifications',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
);

AndroidNotificationChannel _channelForType(dynamic type) {
  switch (type?.toString()) {
    case 'sos_alert':
    case 'location_alert':
      return _emergencyChannel;
    default:
      return _reminderChannel;
  }
}

AndroidNotificationDetails _androidDetails(AndroidNotificationChannel ch) {
  return AndroidNotificationDetails(
    ch.id,
    ch.name,
    channelDescription: ch.description,
    importance: ch.importance,
    priority: Priority.high,
    fullScreenIntent: ch.id == 'emergency_channel',
    color: ch.id == 'emergency_channel'
        ? const Color(0xFFFF0000)
        : const Color(0xFF00897B), // Teal for reminders
    playSound: true,
    enableVibration: true,
    visibility: NotificationVisibility.public,
    styleInformation: const BigTextStyleInformation(''),
    sound: ch.id == 'reminder_channel'
        ? const RawResourceAndroidNotificationSound('gentle_tone')
        : null,
  );
}

// Stable numeric ID: same FCM message → same ID (natural deduplication)
int _stableNotificationId(RemoteMessage message) {
  return (message.messageId ?? message.data.toString()).hashCode;
}

// Payload format: "type|reminder_id"   e.g.  "reminder|abc-123"
String _buildPayload(Map<String, dynamic> data) {
  final type = data['type'] ?? 'reminder';
  final id = data['reminder_id'] ?? data['id'] ?? '';
  return '$type|$id';
}

// ─────────────────────────────────────────────────────────────────────────────
// FCMService
//
// Production-grade Firebase Cloud Messaging integration.
//
// Features:
//   ✅ Permission request (Android 13+ / iOS)
//   ✅ Token fetch → correct Supabase table (caregiver_profiles OR patients)
//   ✅ 3× retry with exponential backoff on token save failure
//   ✅ Token refresh listener (auto-updates Supabase)
//   ✅ Token cleared on logout
//   ✅ Foreground / background / terminated notification handlers
//   ✅ In-session deduplication via seen-message-ID set
//   ✅ Notification tap routing via GoRouter (/alert/:id)
//   ✅ Android channel creation (reminder_channel + emergency_channel)
// ─────────────────────────────────────────────────────────────────────────────
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final SupabaseClient _supabase;

  // Deduplication — seen message IDs in this session
  final Set<String> _seenIds = {};

  FCMService(this._supabase);

  // ── Navigation key (injected from main.dart) ───────────────────────────────

  static GlobalKey<NavigatorState>? _navKey;

  /// Must be called from main.dart after ProviderContainer is created.
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navKey = key;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Initialize FCM. Call once from main.dart after Firebase.initializeApp().
  Future<void> initialize() async {
    // 1. Register background handler FIRST
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Request permission
    final granted = await _requestPermission();
    if (!granted) {
      debugPrint('[FCM] Permission denied — push notifications disabled.');
      return;
    }

    // 3. Set up local notification channels
    await _initLocalNotifications();

    // 4. Fetch and save initial token
    await _fetchAndSaveToken();

    // 5. Listen for token refresh
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed.');
      _saveTokenWithRetry(token);
    });

    // 6. iOS foreground presentation
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 7. Message handlers
    _registerHandlers();

    debugPrint('[FCM] Initialized.');
  }

  /// Clear token from Supabase and delete from Firebase on logout.
  Future<void> onLogout() async {
    try {
      await _clearTokenFromSupabase();
      await _messaging.deleteToken();
      _seenIds.clear();
      debugPrint('[FCM] Logged out — token cleared.');
    } catch (e) {
      debugPrint('[FCM] Logout cleanup error: $e');
    }
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<bool> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
      announcement: false,
      carPlay: false,
    );
    debugPrint('[FCM] Auth status: ${settings.authorizationStatus}');
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  // ── Local Notifications ────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestSoundPermission: true,
          requestBadgePermission: true,
          requestAlertPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationTapped,
    );

    final android = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(_reminderChannel);
    await android?.createNotificationChannel(_emergencyChannel);

    debugPrint('[FCM] Notification channels created.');
  }

  // ── Token Management ───────────────────────────────────────────────────────

  Future<void> _fetchAndSaveToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveTokenWithRetry(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error fetching token: $e');
    }
  }

  /// Saves token to correct Supabase table (caregiver_profiles or patients).
  /// Retries up to 3× with exponential backoff.
  Future<void> _saveTokenWithRetry(String token) async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _saveToken(token);
        return;
      } catch (e) {
        debugPrint('[FCM] Token save attempt $attempt failed: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: 1 << attempt)); // 2s, 4s, 8s
        }
      }
    }
    debugPrint('[FCM] Token save failed after $maxRetries attempts.');
  }

  Future<void> _saveToken(String token) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[FCM] No logged-in user — skipping token save.');
      return;
    }

    // 1. Try caregiver_profiles first
    final caregiverRow = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (caregiverRow != null) {
      await _supabase
          .from('caregiver_profiles')
          .update({'fcm_token': token}).eq('user_id', userId);
      debugPrint('[FCM] Token saved → caregiver_profiles');
      return;
    }

    // 2. Fall back to patients table
    final patientRow = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (patientRow != null) {
      await _supabase
          .from('patients')
          .update({'fcm_token': token}).eq('user_id', userId);
      debugPrint('[FCM] Token saved → patients');
      return;
    }

    debugPrint('[FCM] No profile found for user $userId — token not saved.');
  }

  Future<void> _clearTokenFromSupabase() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await Future.wait([
      _supabase
          .from('caregiver_profiles')
          .update({'fcm_token': null})
          .eq('user_id', userId)
          .then((_) {})
          .catchError((_) {}),
      _supabase
          .from('patients')
          .update({'fcm_token': null})
          .eq('user_id', userId)
          .then((_) {})
          .catchError((_) {}),
    ]);
  }

  // ── Message Handlers ───────────────────────────────────────────────────────

  void _registerHandlers() {
    // FOREGROUND: App open and visible
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // BACKGROUND TAP: User taps notification while app is backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      debugPrint('[FCM] Background tap: ${msg.messageId}');
      _routeFromData(msg.data);
    });

    // TERMINATED TAP: App launched by tapping a notification
    _messaging.getInitialMessage().then((msg) {
      if (msg != null) {
        debugPrint('[FCM] Terminated tap: ${msg.messageId}');
        // Delay until widget tree is fully mounted
        Future.delayed(const Duration(milliseconds: 600), () {
          _routeFromData(msg.data);
        });
      }
    });
  }

  Future<void> _handleForeground(RemoteMessage message) async {
    final msgId = message.messageId ?? message.data.toString();

    // Deduplication guard
    if (_seenIds.contains(msgId)) {
      debugPrint('[FCM] Duplicate skipped: $msgId');
      return;
    }
    _seenIds.add(msgId);
    if (_seenIds.length > 100) _seenIds.remove(_seenIds.first);

    final channel = _channelForType(message.data['type']);
    final id = _stableNotificationId(message);
    final title = message.notification?.title ??
        message.data['title'] as String? ??
        'MemoCare';
    final body =
        message.notification?.body ?? message.data['body'] as String? ?? '';

    if (body.isNotEmpty) {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails:
            NotificationDetails(android: _androidDetails(channel)),
        payload: _buildPayload(message.data),
      );
    }
  }

  // ── Navigation Routing ─────────────────────────────────────────────────────

  void _routeFromData(Map<String, dynamic> data) {
    final type = data['type']?.toString();
    final reminderId = data['reminder_id']?.toString();

    switch (type) {
      case 'reminder':
        if (reminderId != null && reminderId.isNotEmpty) {
          _navKey?.currentState?.pushNamed('/alert/$reminderId');
        }
        break;
      case 'sos_alert':
        debugPrint('[FCM] SOS tap — route to emergency screen.');
        break;
      default:
        debugPrint('[FCM] No route for type: $type');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[FCM] Local notification tapped: ${response.payload}');
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    // Payload format: "type|id"
    final parts = payload.split('|');
    if (parts.length < 2) return;

    final type = parts[0];
    final id = parts[1];

    if (type == 'reminder' && id.isNotEmpty) {
      _navKey?.currentState?.pushNamed('/alert/$id');
    }
  }
}
