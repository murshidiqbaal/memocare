import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/safe_zone.dart';
import '../../data/repositories/safe_zone_repository.dart';
import '../../providers/service_providers.dart';

final safeZoneRepositoryProvider = Provider<SafeZoneRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SafeZoneRepository(supabase);
});

final patientSafeZoneProvider =
    FutureProvider.family<SafeZone?, String>((ref, patientId) async {
  final repository = ref.watch(safeZoneRepositoryProvider);
  return repository.getPatientSafeZone(patientId);
});

class SafeZoneState {
  final bool isLoading;
  final String? error;

  SafeZoneState({this.isLoading = false, this.error});

  SafeZoneState copyWith({bool? isLoading, String? error}) {
    return SafeZoneState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SafeZoneController extends StateNotifier<SafeZoneState> {
  final SafeZoneRepository _repository;
  final Ref _ref;

  SafeZoneController(this._repository, this._ref) : super(SafeZoneState());

  Future<bool> saveSafeZone({
    required String patientId,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required String label,
    String? existingId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final now = DateTime.now();
      final zone = SafeZone(
        id: existingId ?? const Uuid().v4(),
        patientId: patientId,
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
        label: label,
        createdAt: now,
        updatedAt: now,
      );

      await _repository.upsertSafeZone(zone);

      // Invalidate the cache so listeners naturally refetch the new zone
      _ref.invalidate(patientSafeZoneProvider(patientId));

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final safeZoneControllerProvider =
    StateNotifierProvider<SafeZoneController, SafeZoneState>((ref) {
  final repository = ref.watch(safeZoneRepositoryProvider);
  return SafeZoneController(repository, ref);
});
