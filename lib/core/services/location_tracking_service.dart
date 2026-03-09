import 'dart:async';

import 'package:dementia_care_app/data/models/location_alert.dart';
import 'package:dementia_care_app/data/models/patient_home_location.dart';
import 'package:dementia_care_app/data/repositories/location_repository.dart';
import 'package:dementia_care_app/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _activePatientId;

  // Safe Zone Status
  // 0 = Safe, 1 = Near Boundary, 2 = Outside, -1 = No Home Set
  int currentStatus = 0;
  final StreamController<int> statusStreamController =
      StreamController<int>.broadcast();

  LocationTrackingService(
      this._locationRepo, this._notifService, this._supabase);

  Future<void> startTracking(String patientId) async {
    // Prevent duplicate start for same patient
    if (_activePatientId == patientId && _trackingTimer != null) {
      // Still emit current status to new listeners
      statusStreamController.add(currentStatus);
      return;
    }

    _activePatientId = patientId;

    // Requirement: Emit initial 'Safe' (0) immediately to prevent stuck loading
    statusStreamController.add(currentStatus);

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
    try {
      _currentHome = await _locationRepo.getPatientHomeLocation(patientId);
      if (_currentHome == null) {
        // -1 = Safe zone not configured
        currentStatus = -1;
        statusStreamController.add(currentStatus);
        return;
      }
    } catch (e) {
      print('Error fetching home location: $e');
    }

    // 3. Start Timer (runs every 45 seconds)
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 45), (timer) async {
      await _checkLocation(patientId);
    });

    // Also run immediately to update status from '0' to actual
    await _checkLocation(patientId);
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _activePatientId = null;
  }

  Future<void> _checkLocation(String patientId) async {
    if (_currentHome == null) {
      // Re-fetch in case it was set recently
      _currentHome = await _locationRepo.getPatientHomeLocation(patientId);
      if (_currentHome == null) {
        if (currentStatus != -1) {
          currentStatus = -1;
          statusStreamController.add(currentStatus);
        }
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
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

    // Attempt to find linked caregiver to notify
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
    } catch (e) {}

    try {
      await _locationRepo.insertLocationAlert(
        patientId: patientId,
        caregiverId: caregiverId ?? '',
        latitude: lat,
        longitude: lng,
        distanceMeters: distance,
      );

      _lastAlertTime = DateTime.now();

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
// Refactored to auto-trigger tracking when patient profile is ready
final safetyStatusProvider = StreamProvider<int>((ref) {
  final service = ref.watch(locationTrackingServiceProvider);
  final profileAsync = ref.watch(userProfileProvider);

  profileAsync.whenData((profile) {
    if (profile != null && profile.role == 'patient') {
      service.startTracking(profile.id);
    }
  });

  return service.statusStreamController.stream;
});

// Realtime Caregiver Alerts Stream Provider
final realtimeLocationAlertsProvider =
    StreamProvider.family<List<LocationAlert>, String>((ref, caregiverId) {
  final repo = ref.watch(locationRepositoryProvider);
  return repo.streamCaregiverAlerts(caregiverId);
});
