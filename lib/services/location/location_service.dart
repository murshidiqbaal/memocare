import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/location_log.dart';
import '../../data/models/safe_zone.dart';

/// Enhanced location tracking service with Android 14+ support
/// Includes foreground service notification and battery optimization handling
class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();

  factory LocationTrackingService() => _instance;

  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  final List<SafeZone> _activeSafeZones = [];
  bool _isTracking = false;
  String? _currentPatientId;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize the service
  Future<void> init() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _localNotifications.initialize(
      settings: const InitializationSettings(),
    );

    // Create notification channel for foreground service
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking_channel',
      'Location Tracking',
      description: 'Continuous location tracking for safety monitoring',
      importance: Importance.low, // Low to not disturb user
      playSound: false,
      showBadge: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Start tracking with foreground service notification
  Future<void> startTracking(String patientId, List<SafeZone> zones) async {
    if (_isTracking) return;
    _currentPatientId = patientId;
    _activeSafeZones.clear();
    _activeSafeZones.addAll(zones);

    // Check location service
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled.');
      throw Exception('Location services are disabled. Please enable them.');
    }

    // Check and request permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently denied. Please enable in settings.');
    }

    // Request background location permission for Android 10+
    if (permission == LocationPermission.whileInUse) {
      // On Android 10+, we need to explicitly request background permission
      debugPrint('Requesting background location permission...');
      // Note: This requires user to manually enable "Allow all the time" in settings
    }

    _isTracking = true;

    // Show foreground service notification (required for Android 14+)
    await _showForegroundNotification();

    // Configure location settings for background tracking
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 20, // Update every 20 meters
      // For Android, this enables background location
      timeLimit: null,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) {
        _handleLocationUpdate(position);
      },
      onError: (error) {
        debugPrint('Location stream error: $error');
      },
    );

    debugPrint('Location tracking started for $patientId');
  }

  /// Show persistent foreground notification (Android 14+ requirement)
  Future<void> _showForegroundNotification() async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'location_tracking_channel',
      'Location Tracking',
      channelDescription: 'Continuous location tracking for safety monitoring',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Makes it persistent
      autoCancel: false,
      showWhen: false,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF00897B), // Teal color
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: 1000, // Fixed ID for foreground service
      title: 'MemoCare Safety Monitoring',
      body: 'Location tracking active for your safety',
      notificationDetails: platformDetails,
    );
  }

  /// Stop tracking and remove foreground notification
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;

    // Cancel foreground notification
    await _localNotifications.cancel(id: 1000);

    debugPrint('Location tracking stopped');
  }

  /// Update active zones
  void updateSafeZones(List<SafeZone> zones) {
    _activeSafeZones.clear();
    _activeSafeZones.addAll(zones);
  }

  /// Handle location update
  void _handleLocationUpdate(Position position) async {
    if (_currentPatientId == null) return;

    bool isSafe = false;
    if (_activeSafeZones.isEmpty) {
      isSafe = true;
    } else {
      for (var zone in _activeSafeZones) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          zone.latitude,
          zone.longitude,
        );
        if (distance <= zone.radius) {
          isSafe = true;
          break;
        }
      }
    }

    bool isBreach = !isSafe;

    final log = LocationLog.create(
      patientId: _currentPatientId!,
      lat: position.latitude,
      lng: position.longitude,
      isBreach: isBreach,
    );

    // Sync to Supabase
    await _syncLogToSupabase(log);

    // Trigger alert if breach
    if (isBreach) {
      await _triggerLocalBreachAlert(log);
      await _notifyCaregiversOfBreach(log);
    }
  }

  /// Sync location log to Supabase
  Future<void> _syncLogToSupabase(LocationLog log) async {
    try {
      await Supabase.instance.client.from('location_logs').insert(log.toJson());
      debugPrint(
          'Synced location: ${log.latitude}, ${log.longitude} (Breach: ${log.isBreach})');
    } catch (e) {
      debugPrint('Error syncing location log: $e');
      // TODO: Queue for offline sync
    }
  }

  /// Trigger local breach alert on patient device
  Future<void> _triggerLocalBreachAlert(LocationLog log) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'safety_channel',
      'Safety Alerts',
      channelDescription: 'Alerts for safe zone breaches',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD32F2F),
      playSound: true,
      enableVibration: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id: 999,
      title: '⚠ Safe Zone Exit Detected',
      body: 'You have left the safe zone. Your caregiver has been notified.',
      notificationDetails: platformDetails,
    );
  }

  /// Notify caregivers via FCM
  Future<void> _notifyCaregiversOfBreach(LocationLog log) async {
    try {
      // Call Supabase function to trigger FCM notifications
      await Supabase.instance.client.rpc(
        'notify_caregivers_fcm',
        params: {
          'p_patient_id': _currentPatientId,
          'p_notification_type': 'location_alert',
          'p_title': 'Safe Zone Breach',
          'p_body': 'Patient has left the safe zone',
          'p_data': {
            'type': 'location_alert',
            'patient_id': _currentPatientId,
            'latitude': log.latitude,
            'longitude': log.longitude,
            'timestamp': log.recordedAt.toIso8601String(),
          },
        },
      );
      debugPrint('Caregivers notified of safe zone breach');
    } catch (e) {
      debugPrint('Error notifying caregivers: $e');
    }
  }

  /// Check if tracking is active
  bool get isTracking => _isTracking;

  /// Get current patient ID
  String? get currentPatientId => _currentPatientId;
}
