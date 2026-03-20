import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memocare/data/models/patient_location.dart';
import 'package:memocare/data/models/safe_zone.dart';
import 'package:memocare/features/location/models/safezone_alert.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Continuously monitors a patient's location against their safe zone.
///
/// Flow:
///   1. [startMonitoring] — starts a geolocator stream (interval: 30 s / 50 m)
///   2. Each position update calls [checkSafeZone]
///   3. On first exit → inserts `safezone_alerts` row + sends FCM via Supabase Edge Function
///   4. On re-entry → sends "returned home" alert
///   5. [_isOutsideZone] flag prevents duplicate alerts
class SafeZoneService {
  final SupabaseClient _supabase;

  StreamSubscription<Position>? _positionSub;
  bool _isOutsideZone = false;
  SafeZone? _currentZone;
  String? _patientId;

  SafeZoneService(this._supabase);

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Starts continuous monitoring for [patientId] against [safeZone].
  Future<void> startMonitoring({
    required String patientId,
    required SafeZone safeZone,
  }) async {
    await stopMonitoring(); // teardown existing subscription

    // Resolve internal patient ID if auth ID was passed
    final patientRow = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();

    final String resolvedId = patientRow?['id'] ?? patientId;

    _patientId = resolvedId;
    _currentZone = safeZone;

    print(
        'Starting SafeZone Monitoring for Patient: $resolvedId (Input: $patientId)');

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      debugPrint(
          '[SafeZoneService] Location permission denied — cannot monitor.');
      return;
    }

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // metres
      intervalDuration: const Duration(seconds: 30),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: 'MemoCare is monitoring your safe zone.',
        notificationTitle: 'Safe Zone Active',
        enableWakeLock: true,
      ),
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPosition,
      onError: (e) => debugPrint('[SafeZoneService] Stream error: $e'),
    );

    debugPrint('[SafeZoneService] Monitoring started for patient $resolvedId');
  }

  /// Stops the location stream.
  Future<void> stopMonitoring() async {
    await _positionSub?.cancel();
    _positionSub = null;
    debugPrint('[SafeZoneService] Monitoring stopped.');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _onPosition(Position position) async {
    if (_currentZone == null || _patientId == null) return;

    // 1. Upload live location to Supabase
    await _uploadLocation(position);

    // 2. Evaluate geofence
    final distance = calculateDistance(
      position.latitude,
      position.longitude,
      _currentZone!.latitude,
      _currentZone!.longitude,
    );

    debugPrint(
        '[SafeZoneService] Distance from home: ${distance.toStringAsFixed(1)} m (radius: ${_currentZone!.radiusMeters} m)');

    final isOutside = distance > _currentZone!.radiusMeters;

    if (isOutside && !_isOutsideZone) {
      _isOutsideZone = true;
      await _triggerAlert(
        position: position,
        alertType: SafeZoneAlertType.leftZone,
      );
    } else if (!isOutside && _isOutsideZone) {
      _isOutsideZone = false;
      await _triggerAlert(
        position: position,
        alertType: SafeZoneAlertType.returnedHome,
      );
    }
  }

  Future<void> _uploadLocation(Position pos) async {
    if (_patientId == null) return;
    try {
      final location = PatientLocation(
        patientId: _patientId!,
        lat: pos.latitude,
        lng: pos.longitude,
        updatedAt: DateTime.now().toUtc(),
      );
      final payload = location.toJson();
      debugPrint('[SafeZoneService] Upserting location payload: $payload');
      await _supabase.from('patient_locations').upsert(
            payload,
            onConflict: 'patient_id',
          );
    } catch (e) {
      debugPrint('[SafeZoneService] Location upload error: $e');
    }
  }

  Future<void> _triggerAlert({
    required Position position,
    required SafeZoneAlertType alertType,
  }) async {
    try {
      // 1. Insert alert row
      await _supabase.from('safezone_alerts').insert({
        'patient_id': _patientId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'alert_type': alertType == SafeZoneAlertType.leftZone
            ? 'left_zone'
            : 'returned_home',
      });

      // 2. Invoke Supabase Edge Function to send FCM push to caregivers
      final payload = {
        'patient_id': _patientId,
        'alert_type': alertType == SafeZoneAlertType.leftZone
            ? 'left_zone'
            : 'returned_home',
        'latitude': position.latitude,
        'longitude': position.longitude,
      };

      await _supabase.functions.invoke(
        'notify-safezone-alert',
        body: payload,
      );

      debugPrint('[SafeZoneService] Alert triggered: ${alertType.name}');
    } catch (e) {
      debugPrint('[SafeZoneService] Alert trigger error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Haversine distance calculation
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns the great-circle distance between two lat/lng points in **metres**.
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRad(double deg) => deg * pi / 180;

  void dispose() {
    _positionSub?.cancel();
    _positionSub = null;
  }
}
