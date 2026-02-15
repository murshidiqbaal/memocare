import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/patient.dart';
import '../data/repositories/patient_connection_repository.dart';

/// Provider for the Patient Connection Repository
final patientConnectionRepositoryProvider =
    Provider<PatientConnectionRepository>((ref) {
  return PatientConnectionRepository(Supabase.instance.client);
});

/// Stream of Connected Patients (Real-time)
final connectedPatientsStreamProvider = StreamProvider<List<Patient>>((ref) {
  final repo = ref.watch(patientConnectionRepositoryProvider);
  return repo.getConnectedPatientsStream();
});

/// Controller for Connection Actions (Connect/Remove)
final caregiverConnectionControllerProvider =
    AsyncNotifierProvider<CaregiverConnectionController, void>(() {
  return CaregiverConnectionController();
});

class CaregiverConnectionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // No initial state to build
  }

  Future<void> connectUsingInviteCode(String code) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(patientConnectionRepositoryProvider)
          .connectUsingInviteCode(code);
      // Stream automatically updates, no need to refresh manually
    });
  }

  Future<void> removeConnection(String patientId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(patientConnectionRepositoryProvider)
          .removeConnection(patientId);
    });
  }
}
