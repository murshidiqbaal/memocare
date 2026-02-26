import 'dart:async';

import '../../../../data/models/location_log.dart';
import '../../../../data/models/safe_zone.dart';

// Mock Data Service for demo
class MockSafetyService {
  Stream<LocationLog> getLocationStream() async* {
    double lat = 37.422;
    double lng = -122.084;

    // Simulate movement
    for (int i = 0; i < 1000; i++) {
      await Future.delayed(const Duration(seconds: 2));
      // Random walk
      lat += (i % 2 == 0 ? 0.0001 : -0.0001);
      // Breach condition occasionally
      bool breach = i > 10 && i < 15;

      yield LocationLog(
          id: 'log_$i',
          patientId: 'patient_1',
          latitude: lat,
          longitude: lng,
          recordedAt: DateTime.now(),
          isBreach: breach);
    }
  }

  Future<SafeZone> getActiveZone() async {
    return SafeZone(
        id: 'mnock_zone',
        patientId: 'patient_1',
        latitude: 37.422,
        longitude: -122.084,
        radiusMeters: 100,
        label: 'Home',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now());
  }
}
