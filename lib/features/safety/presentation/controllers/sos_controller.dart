import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../providers/auth_provider.dart';
import '../../data/models/live_location.dart';
import '../../data/models/sos_alert.dart';
import '../../data/repositories/sos_repository.dart';

// --- State ---

/// Holds the current active SOS alert for the logged-in patient (if any)
final activeSosAlertProvider = StateProvider<SosAlert?>((ref) => null);

/// Controller for SOS actions
class SosController extends StateNotifier<AsyncValue<void>> {
  final SosRepository _repository;
  final Ref _ref;
  StreamSubscription<Position>? _positionStreamSubscription;

  SosController(this._repository, this._ref) : super(const AsyncData(null));

  /// Start an SOS alert
  Future<void> triggerSos() async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(currentUserProvider);
      if (user == null) throw Exception('User not logged in');

      // 1. Get current location
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 2. Create Alert in DB
      final alert = await _repository.createSosAlert(
        user.id,
        position.latitude,
        position.longitude,
      );

      // 3. Update local state
      _ref.read(activeSosAlertProvider.notifier).state = alert;

      // 4. Start tracking location
      _startLocationTracking(user.id);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Stop tracking and mark resolved (Patient side if implemented, or just stop tracking)
  /// Typically caregiver resolves it, but patient might want to cancel.
  Future<void> cancelSos() async {
    final alert = _ref.read(activeSosAlertProvider);
    if (alert != null) {
      await _repository.resolveSosAlert(alert.id);
      _stopLocationTracking();
      _ref.read(activeSosAlertProvider.notifier).state = null;
    }
  }

  /// Caregiver resolves the alert
  Future<void> resolveSos(String alertId) async {
    state = const AsyncLoading();
    try {
      await _repository.resolveSosAlert(alertId);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void _startLocationTracking(String patientId) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Update every 10 meters
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings)
            .listen((Position? position) {
      if (position != null) {
        _repository.updateLiveLocation(
          patientId,
          position.latitude,
          position.longitude,
        );
      }
    });
  }

  void _stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }
}

final sosControllerProvider =
    StateNotifierProvider<SosController, AsyncValue<void>>((ref) {
  final repo = ref.watch(sosRepositoryProvider);
  return SosController(repo, ref);
});

// --- Stream Providers for Caregivers ---

/// Stream of ALL active alerts visible to the user (Caregiver View)
final activeAlertsStreamProvider = StreamProvider<List<SosAlert>>((ref) {
  final repo = ref.watch(sosRepositoryProvider);
  return repo.streamActiveAlerts();
});

/// Stream of live location for a specific patient (for Map View)
final liveLocationStreamProvider =
    StreamProvider.family<List<LiveLocation>, String>((ref, patientId) {
  final repo = ref.watch(sosRepositoryProvider);
  return repo.streamLiveLocation(patientId);
});
