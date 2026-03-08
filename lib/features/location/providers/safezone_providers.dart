import 'package:dementia_care_app/data/models/safe_zone.dart';
import 'package:dementia_care_app/features/location/models/location_change_request.dart';
import 'package:dementia_care_app/features/location/services/location_change_request_service.dart';
import 'package:dementia_care_app/features/location/services/safezone_service.dart';
import 'package:dementia_care_app/providers/safe_zone_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/supabase_provider.dart';

// ─── Service providers ─────────────────────────────────────────────────────

final safeZoneServiceProvider = Provider<SafeZoneService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final service = SafeZoneService(supabase);
  ref.onDispose(service.dispose);
  return service;
});

// Provider for location change request service

final locationChangeRequestServiceProvider =
    Provider<LocationChangeRequestService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final safeZoneRepo = ref.watch(safeZoneRepositoryProvider);
  return LocationChangeRequestService(
    supabase: supabase,
    safeZoneRepository: safeZoneRepo,
  );
});

// ─── Safe zone monitoring ───────────────────────────────────────────────────

/// Notifier that starts/stops the background location monitor.
class SafeZoneMonitoringNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {} // idle by default

  Future<void> start({
    required String patientId,
    required SafeZone safeZone,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(safeZoneServiceProvider).startMonitoring(
            patientId: patientId,
            safeZone: safeZone,
          );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> stop() async {
    await ref.read(safeZoneServiceProvider).stopMonitoring();
    state = const AsyncData(null);
  }
}

final safeZoneMonitoringProvider =
    AsyncNotifierProvider<SafeZoneMonitoringNotifier, void>(
  SafeZoneMonitoringNotifier.new,
);

// ─── Location change requests ─────────────────────────────────────────────

/// Pending requests for a given caregiver ID.
final pendingLocationRequestsProvider =
    FutureProvider.autoDispose.family<List<LocationChangeRequest>, String>(
  (ref, caregiverId) async {
    final svc = ref.watch(locationChangeRequestServiceProvider);
    return svc.getPendingRequestsForCaregiver(caregiverId);
  },
);

/// All requests for a patient (for showing status history).
final patientLocationRequestsProvider =
    FutureProvider.autoDispose.family<List<LocationChangeRequest>, String>(
  (ref, patientId) async {
    final svc = ref.watch(locationChangeRequestServiceProvider);
    return svc.getPatientRequests(patientId);
  },
);

/// Pending REQUESTED requests for a given patient ID.
final patientPendingRequestsProvider =
    FutureProvider.autoDispose.family<List<LocationChangeRequest>, String>(
  (ref, patientId) async {
    final svc = ref.watch(locationChangeRequestServiceProvider);
    return svc.getPatientPendingRequests(patientId);
  },
);
