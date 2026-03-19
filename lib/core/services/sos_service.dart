import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memocare/providers/service_providers.dart';
import 'package:memocare/services/reminder_notification_service.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/sos_message.dart';
import '../../../providers/supabase_provider.dart';
import '../../features/sos/data/repositories/sos_system_repository.dart';

final sosServiceProvider = Provider<SosService>((ref) {
  return SosService(
    ref.watch(supabaseClientProvider),
    ref.watch(sosSystemRepositoryProvider),
    ref.watch(reminderNotificationServiceProvider),
  );
});

class SosService {
  final SupabaseClient _supabase;
  final SosSystemRepository _sosRepo;
  final ReminderNotificationService _notifService;

  StreamSubscription<UserAccelerometerEvent>? _accelSub;

  String? _activePatientId;
  DateTime? _lastSosTime;
  
  // Shake detection state
  DateTime? _lastShakeTime;
  int _shakeCount = 0;
  static const double _shakeThreshold = 25.0; // ~2.5G

  SosService(this._supabase, this._sosRepo, this._notifService);

  void startSafetyMonitoring(String patientId) {
    _activePatientId = patientId;

    // Combined sensor monitoring (Shake + Fall)
    _accelSub?.cancel();
    _accelSub = userAccelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 100) // Increased frequency for shake
    ).listen((UserAccelerometerEvent event) {
      // Calculate magnitude
      double magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);

      // 1. Shake Detection Logic
      if (magnitude > _shakeThreshold) {
        final now = DateTime.now();
        // If within 500ms of last shake, it's a continuing shake
        if (_lastShakeTime != null && now.difference(_lastShakeTime!).inMilliseconds < 500) {
          _shakeCount++;
        } else {
          _shakeCount = 1;
        }
        _lastShakeTime = now;

        if (_shakeCount >= 3) {
          _triggerEmergency('Shake SOS Triggered');
          _shakeCount = 0;
        }
      }

      // 2. Fall Detection Logic (Sudden high-impact)
      if (magnitude > 35.0) { // Higher threshold for fall/impact
        _triggerEmergency('Fall Detected (Automated SOS)');
      }
    });
  }

  void stopSafetyMonitoring() {
    _accelSub?.cancel();
    _activePatientId = null;
  }

  Future<void> triggerManualSos() async {
    await _triggerEmergency('Manual SOS Button Pressed');
  }

  Future<void> triggerSafeZoneBreach() async {
    await _triggerEmergency('Patient left safe zone');
  }

  Future<void> _triggerEmergency(String note) async {
    if (_activePatientId == null) return;

    // Prevent spamming (throttle to 1 SOS per minute automatically)
    if (_lastSosTime != null &&
        DateTime.now().difference(_lastSosTime!).inMinutes < 1) {
      return;
    }

    try {
      // Get Caregiver ID
      final linkResponse = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', _activePatientId as Object)
          .maybeSingle();

      if (linkResponse == null) return;
      final caregiverId = linkResponse['caregiver_id'] as String;

      // Get Location
      double lat = 0.0, lng = 0.0;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (e) {
        // Fallback or ignore if location fails
      }

      final sos = SosMessage(
        patientId: _activePatientId!,
        caregiverId: caregiverId,
        triggeredAt: DateTime.now().toUtc(),
        locationLat: lat,
        locationLng: lng,
        note: note,
      );

      await _sosRepo.insertSosMessage(sos);
      _lastSosTime = DateTime.now();

      // Notify Patient Locally
      await _notifService.showEmergencyNotification(
        title: 'SOS Sent!',
        body: 'Emergency alert sent to caregiver: $note',
      );
    } catch (e) {
      print('Failed to trigger SOS: $e');
    }
  }
}
