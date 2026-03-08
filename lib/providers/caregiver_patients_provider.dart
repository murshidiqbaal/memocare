// caregiver_patient_connection.dart

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/patient.dart';
import 'active_patient_provider.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

/// ---------------------------------------------------------------------------
/// STREAM: Real-time connected patients for caregiver
/// ---------------------------------------------------------------------------

final connectedPatientsStreamProvider =
    StreamProvider.autoDispose<List<Patient>>((ref) {
  final repo = ref.watch(patientConnectionRepositoryProvider);
  return repo.getConnectedPatientsStream();
});

/// ---------------------------------------------------------------------------
/// CONTROLLER: Handles connection actions
/// ---------------------------------------------------------------------------

final caregiverConnectionControllerProvider =
    AsyncNotifierProvider<CaregiverConnectionController, void>(
        CaregiverConnectionController.new);

class CaregiverConnectionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Nothing to initialize
    return null;
  }

  /// Connect caregiver using patient invite code
  Future<void> connectUsingInviteCode(String code) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(patientConnectionRepositoryProvider)
          .connectUsingInviteCode(code);
    });
  }

  /// Remove connection between caregiver and patient
  Future<void> removeConnection(String patientId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref
          .read(patientConnectionRepositoryProvider)
          .removeConnection(patientId);
    });
  }

  /// Create a patient and link to caregiver
  Future<void> createAndLinkPatient({
    required String name,
    int? age,
    String? condition,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final user = ref.read(currentUserProvider);

      if (user == null) {
        throw Exception("User not logged in");
      }

      final repo = ref.read(patientRepositoryProvider);

      /// Create patient
      final patientId = await repo.createPatient(
        name: name,
        age: age,
        condition: condition,
      );

      /// Link caregiver to patient
      await repo.linkPatientToCaregiver(
        patientId: patientId,
        caregiverUserId: user.id,
      );

      /// Refresh caregiver patients list
      ref.invalidate(caregiverPatientsProvider);
    });
  }
}

/// ---------------------------------------------------------------------------
/// FUTURE: Fetch caregiver patients (one-time fetch)
/// ---------------------------------------------------------------------------

final caregiverPatientsProvider =
    FutureProvider.autoDispose<List<Patient>>((ref) async {
  return ref.watch(linkedPatientsProvider.future);
});
