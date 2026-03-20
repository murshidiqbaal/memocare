import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memocare/data/models/patient_location.dart';
import 'package:memocare/data/models/safe_zone.dart';
import '../../data/repositories/safe_zone_repository.dart';
import '../../features/sos/data/repositories/sos_system_repository.dart';

// Provide the LocationTrackingService
final locationTrackingServiceProvider =
    Provider<LocationTrackingService>((ref) {
  final safeZoneRepo = ref.watch(safeZoneRepositoryProvider);
  final sosSysRepo = ref.watch(sosSystemRepositoryProvider);
  return LocationTrackingService(safeZoneRepo, sosSysRepo);
});

class LocationTrackingService {
  final SafeZoneRepository _safeZoneRepo;
  final SosSystemRepository _sosSysRepo;

  Timer? _trackingTimer;
  SafeZone? _currentHome;
  String? _activePatientId;

  // Safe Zone Status
  // 0 = Safe, 1 = Near Boundary, 2 = Outside, -1 = No Home Set
  int currentStatus = 0;
  final StreamController<int> statusStreamController =
      StreamController<int>.broadcast();

  LocationTrackingService(this._safeZoneRepo, this._sosSysRepo);

  Future<void> startTracking(String patientId) async {
    // Prevent duplicate start
    if (_activePatientId == patientId && _trackingTimer != null) {
      statusStreamController.add(currentStatus);
      return;
    }

    _activePatientId = patientId;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Fetch safe zone
    try {
      _currentHome = await _safeZoneRepo.getPatientSafeZone(patientId);
      if (_currentHome == null) {
        currentStatus = -1;
        statusStreamController.add(currentStatus);
      }
    } catch (e) {
      print('Error fetching safe zone: $e');
    }

    // Start 10-second interval logic
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      await _checkLocation();
    });

    await _checkLocation();
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _activePatientId = null;
  }

  Future<void> _checkLocation() async {
    if (_activePatientId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Save live tracking update
      await _sosSysRepo.upsertPatientLocation(
        PatientLocation(
          patientId: _activePatientId!,
          lat: position.latitude,
          lng: position.longitude,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
      
      print('LocationTrackingService: Upserting location payload for $_activePatientId');
    } catch (e) {
      print('Location tracking error: $e');
    }
  }

  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final dist = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return dist;
  }
}

// Provider for observing safety status in UI
final safetyStatusProvider = StreamProvider.family<int, String>((ref, patientId) {
  if (patientId.isEmpty) {
    return Stream.value(-1);
  }

  final sosRepo = ref.watch(sosSystemRepositoryProvider);
  final szRepo = ref.watch(safeZoneRepositoryProvider);

  final controller = StreamController<int>();
  PatientLocation? lastLoc;
  SafeZone? lastZone;

  int computeStatus() {
    if (lastLoc == null || lastZone == null) return -1;

    final distance = LocationTrackingService.calculateDistance(
      lastLoc!.lat,
      lastLoc!.lng,
      lastZone!.latitude,
      lastZone!.longitude,
    );

    if (distance <= lastZone!.radiusMeters) {
      return 0; // Safe at Home
    } else if (distance <= lastZone!.radiusMeters * 1.2) {
      return 1; // Near Boundary
    } else {
      return 2; // Outside Safe Zone
    }
  }

  Future<void> init() async {
    try {
      // 1. Fetch initial data from both tables
      lastLoc = await sosRepo.getLatestPatientLocation(patientId);
      lastZone = await szRepo.getPatientSafeZone(patientId);
      
      final initialStatus = computeStatus();
      print('SafetyStatusProvider($patientId): Initial Load - Loc: $lastLoc, Zone: $lastZone, Status: $initialStatus');
      controller.add(initialStatus);

      // 2. Subscribe to realtime updates
      final locSub = sosRepo.streamPatientLocation(patientId).listen((loc) {
        print('SafetyStatusProvider($patientId): Realtime Location Update: $loc');
        lastLoc = loc;
        if (!controller.isClosed) controller.add(computeStatus());
      });

      final zoneSub = szRepo.streamPatientSafeZone(patientId).listen((zone) {
        print('SafetyStatusProvider($patientId): Realtime SafeZone Update: $zone');
        lastZone = zone;
        if (!controller.isClosed) controller.add(computeStatus());
      });

      ref.onDispose(() {
        locSub.cancel();
        zoneSub.cancel();
        controller.close();
      });
    } catch (e) {
      print('SafetyStatusProvider($patientId) Error: $e');
      if (!controller.isClosed) controller.add(-1);
    }
  }

  init();
  return controller.stream;
});
