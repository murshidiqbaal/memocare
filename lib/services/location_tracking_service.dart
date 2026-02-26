import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/location_alert.dart';
import '../data/models/patient_home_location.dart';
import '../data/repositories/location_repository.dart';
import '../providers/service_providers.dart';
import '../services/notification/reminder_notification_service.dart';

// Provide the LocationRepository
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LocationRepository(supabase);
});

// Provide the LocationTrackingService
final locationTrackingServiceProvider =
    Provider<LocationTrackingService>((ref) {
  final locationRepo = ref.watch(locationRepositoryProvider);
  final notifService = ref.watch(reminderNotificationServiceProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return LocationTrackingService(locationRepo, notifService, supabase);
});

class LocationTrackingService {
  final LocationRepository _locationRepo;
  final ReminderNotificationService _notifService;
  final SupabaseClient _supabase;

  Timer? _trackingTimer;
  DateTime? _lastAlertTime;
  PatientHomeLocation? _currentHome;

  // Safe Zone Status
  // 0 = Safe, 1 = Near Boundary, 2 = Outside
  int currentStatus = 0;
  StreamController<int> statusStreamController =
      StreamController<int>.broadcast();

  LocationTrackingService(
      this._locationRepo, this._notifService, this._supabase);

  Future<void> startTracking(String patientId) async {
    // 1. Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // 2. Fetch home location initially
    _currentHome = await _locationRepo.getPatientHomeLocation(patientId);
    if (_currentHome == null) return;

    // 3. Start Timer (runs every 60 seconds to save battery, handles background if configured)
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 45), (timer) async {
      await _checkLocation(patientId);
    });

    // Also run immediately
    await _checkLocation(patientId);
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }

  Future<void> _checkLocation(String patientId) async {
    if (_currentHome == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        // High accuracy for safety, but can be adjusted for battery
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      double distance = Geolocator.distanceBetween(
        _currentHome!.latitude,
        _currentHome!.longitude,
        position.latitude,
        position.longitude,
      );

      // Update status for UI
      int newStatus = 0;
      if (distance > _currentHome!.radiusMeters) {
        newStatus = 2; // Outside
      } else if (distance > _currentHome!.radiusMeters * 0.8) {
        newStatus = 1; // Near boundary
      }

      if (newStatus != currentStatus) {
        currentStatus = newStatus;
        statusStreamController.add(currentStatus);
      }

      // Check breach
      if (currentStatus == 2) {
        _handleBreach(
            patientId, position.latitude, position.longitude, distance);
      }
    } catch (e) {
      // Handle location errors quietly in background
      print('Location tracking error: $e');
    }
  }

  Future<void> _handleBreach(
      String patientId, double lat, double lng, double distance) async {
    // Prevent duplicate spam within 5 minutes
    if (_lastAlertTime != null &&
        DateTime.now().difference(_lastAlertTime!).inMinutes < 5) {
      return;
    }

    // Attempt to find linked caregiver to notify (for location_alerts table)
    String? caregiverId;
    try {
      final linkResponse = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', patientId)
          .maybeSingle();
      if (linkResponse != null) {
        caregiverId = linkResponse['caregiver_id']?.toString();
      }
    } catch (e) {
      // Ignored
    }

    try {
      // 1. Insert alert in Supabase
      await _locationRepo.insertLocationAlert(
        patientId: patientId,
        caregiverId: caregiverId ?? '',
        latitude: lat,
        longitude: lng,
        distanceMeters: distance,
      );

      _lastAlertTime = DateTime.now();

      // 2. Trigger local SOS feedback for patient
      await _notifService.showEmergencyNotification(
        title: 'SAFETY ALERT',
        body: 'You have left your safe zone. Your caregiver has been notified.',
      );
    } catch (e) {
      print('Error handling breach: $e');
    }
  }
}

// Provider for observing safety status in UI
final safetyStatusProvider = StreamProvider<int>((ref) {
  final service = ref.watch(locationTrackingServiceProvider);
  return service.statusStreamController.stream;
});

// Realtime Caregiver Alerts Stream Provider
final realtimeLocationAlertsProvider =
    StreamProvider.family<List<LocationAlert>, String>((ref, caregiverId) {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.streamCaregiverAlerts(caregiverId);
});
