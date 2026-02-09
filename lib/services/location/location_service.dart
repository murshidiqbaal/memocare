import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/location_log.dart';
import '../../data/models/safe_zone.dart';

/// A service to handle background location tracking, safe zone detection,
/// and syncing logs to Supabase.
class LocationTrackingService {
  static final LocationTrackingService _instance =
      LocationTrackingService._internal();

  factory LocationTrackingService() => _instance;

  LocationTrackingService._internal();

  StreamSubscription<Position>? _positionStreamSubscription;
  final List<SafeZone> _activeSafeZones = [];
  bool _isTracking = false;
  String? _currentPatientId;

  // Notification plugin (assuming initialized in main.dart, but accessible here)
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Start tracking for a specific patient
  Future<void> startTracking(String patientId, List<SafeZone> zones) async {
    if (_isTracking) return;
    _currentPatientId = patientId;
    _activeSafeZones.clear();
    _activeSafeZones.addAll(zones);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services disabled.');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _isTracking = true;

    // Configure for battery efficiency vs accuracy
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high, // High needed for small safe zones
      distanceFilter: 20, // Update every 20 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position position) {
      _handleLocationUpdate(position);
    });

    debugPrint('Location tracking started for $patientId');
  }

  /// Stop tracking
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _isTracking = false;
    debugPrint('Location tracking stopped');
  }

  /// Update active zones (e.g. if caregiver adds one while tracking)
  void updateSafeZones(List<SafeZone> zones) {
    _activeSafeZones.clear();
    _activeSafeZones.addAll(zones);
  }

  /// Logic to run on every location update
  void _handleLocationUpdate(Position position) async {
    if (_currentPatientId == null) return;

    bool isSafe = false;
    // If no zones defined, assume safe or ignore breach logic
    if (_activeSafeZones.isEmpty) {
      isSafe = true;
    } else {
      // Check if inside ANY safe zone
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

    // Create Log
    final log = LocationLog.create(
      patientId: _currentPatientId!,
      lat: position.latitude,
      lng: position.longitude,
      isBreach: isBreach,
    );

    // 1. Save/Sync Log
    _syncLogToSupabase(log);

    // 2. Trigger Alert if Breach
    if (isBreach) {
      _triggerLocalBreachAlert(log);
    }
  }

  Future<void> _syncLogToSupabase(LocationLog log) async {
    try {
      // Stub for Supabase Insert
      // await Supabase.instance.client.from('location_logs').insert(log.toJson());
      debugPrint(
          'Synced location: ${log.latitude}, ${log.longitude} (Breach: ${log.isBreach})');
    } catch (e) {
      debugPrint('Error syncing location log: $e');
      // TODO: Queue for offline sync
    }
  }

  Future<void> _triggerLocalBreachAlert(LocationLog log) async {
    // This runs on the Patient Device.
    // In a real scenario, the syncing to Supabase triggers a Push Notification to the Caregiver.
    // For this module/demo, we might show a notification on the current device
    // (useful if user is testing both roles, or to warn the patient themselves).

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'safety_channel',
      'Safety Alerts',
      channelDescription: 'Alerts for safe zone breaches',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFD32F2F),
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      999,
      '⚠ Safe Zone Exit Detected',
      'It seems you have left the safe zone. Caregiver notified.',
      platformDetails,
    );
  }
}
