import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memocare/data/models/patient_location.dart';
import 'package:memocare/data/models/safe_zone.dart';

// import '../models/patient_location.dart';
// import '../models/safe_zone.dart';
import '../../data/repositories/safe_zone_repository.dart';
// import '../../features/live_location/data/patient_location_model.dart' hide PatientLocation;
import '../../features/sos/data/repositories/sos_system_repository.dart';
import '../../providers/active_patient_provider.dart';
import 'sos_service.dart';

// Provide the LocationTrackingService
final locationTrackingServiceProvider =
    Provider<LocationTrackingService>((ref) {
  final safeZoneRepo = ref.watch(safeZoneRepositoryProvider);
  final sosSysRepo = ref.watch(sosSystemRepositoryProvider);
  final sosService = ref.watch(sosServiceProvider);
  return LocationTrackingService(safeZoneRepo, sosSysRepo, sosService);
});

class LocationTrackingService {
  final SafeZoneRepository _safeZoneRepo;
  final SosSystemRepository _sosSysRepo;
  final SosService _sosService;

  Timer? _trackingTimer;
  DateTime? _lastBreachAlertTime;
  SafeZone? _currentHome;
  String? _activePatientId;

  // Safe Zone Status
  // 0 = Safe, 1 = Near Boundary, 2 = Outside, -1 = No Home Set
  int currentStatus = 0;
  final StreamController<int> statusStreamController =
      StreamController<int>.broadcast();

  LocationTrackingService(
      this._safeZoneRepo, this._sosSysRepo, this._sosService);

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
      await _checkLocation(patientId);
    });

    await _checkLocation(patientId);
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    _activePatientId = null;
  }

  Future<void> _checkLocation(String patientId) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      // Save live location to patient_locations
      final location = PatientLocation(
        patientId: patientId,
        lat: position.latitude,
        lng: position.longitude,
        updatedAt: DateTime.now().toUtc(),
      );
      print(
          'LocationTrackingService: Upserting location payload: ${location.toJson()}');
      await _sosSysRepo.upsertPatientLocation(location);

      // Re-fetch safe zone if missing
      if (_currentHome == null) {
        _currentHome = await _safeZoneRepo.getPatientSafeZone(patientId);
        if (_currentHome == null) {
          if (currentStatus != -1) {
            currentStatus = -1;
            statusStreamController.add(currentStatus);
          }
          return;
        }
      }

      double distance = Geolocator.distanceBetween(
        _currentHome!.homeLat,
        _currentHome!.homeLng,
        position.latitude,
        position.longitude,
      );

      int newStatus = 0;
      if (distance > _currentHome!.radius) {
        newStatus = 2; // Outside
      } else if (distance > _currentHome!.radius * 0.8) {
        newStatus = 1; // Near boundary
      }

      bool forceEmit = (currentStatus == 0 && newStatus == 0);

      if (newStatus != currentStatus || forceEmit) {
        currentStatus = newStatus;
        statusStreamController.add(currentStatus);
      }

      // Check breach
      if (currentStatus == 2) {
        await _handleBreach();
      }
    } catch (e) {
      // Ignore single timeouts
    }
  }

  Future<void> _handleBreach() async {
    if (_lastBreachAlertTime != null &&
        DateTime.now().difference(_lastBreachAlertTime!).inMinutes < 5) {
      return; // Thrashing protection
    }
    await _sosService.triggerSafeZoneBreach();
    _lastBreachAlertTime = DateTime.now();
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
final safetyStatusProvider = StreamProvider<int>((ref) {
  final patientId = ref.watch(activePatientIdProvider);
  if (patientId == null || patientId.isEmpty) {
    return Stream.value(-1);
  }

  final sosRepo = ref.watch(sosSystemRepositoryProvider);
  final szRepo = ref.watch(safeZoneRepositoryProvider);

  final controller = StreamController<int>();

  PatientLocation? lastLoc;
  SafeZone? lastZone;

  void emitStatus() {
    if (controller.isClosed) return;

    if (lastLoc == null || lastZone == null) {
      controller.add(-1);
      return;
    }

    final distance = LocationTrackingService.calculateDistance(
      lastLoc!.lat,
      lastLoc!.lng,
      lastZone!.homeLat,
      lastZone!.homeLng,
    );

    int status = -1;
    if (distance <= lastZone!.radius) {
      status = 0; // Safe at Home
    } else if (distance <= lastZone!.radius * 1.2) {
      status = 1; // Near Boundary
    } else {
      status = 2; // Outside Safe Zone
    }

    controller.add(status);
  }

  final locSub = sosRepo.streamPatientLocation(patientId).listen((loc) {
    lastLoc = loc;
    emitStatus();
  });

  final zoneSub = szRepo.streamPatientSafeZone(patientId).listen((zone) {
    lastZone = zone;
    emitStatus();
  });

  ref.onDispose(() {
    locSub.cancel();
    zoneSub.cancel();
    controller.close();
  });

  return controller.stream;
});
