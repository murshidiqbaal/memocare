import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/caregiver.dart';
import '../data/models/patient.dart';
import '../providers/service_providers.dart';

// REPOSITORIES (Assuming these are provided in service_providers.dart or similar.
// If not, I'll access them via ref.watch on the repository provider)

// -----------------------------------------------------------------------------
// PATIENT SIDE: Linked Caregivers
// -----------------------------------------------------------------------------

final linkedCaregiversProvider =
    FutureProvider.autoDispose<List<Caregiver>>((ref) async {
  final repository = ref.watch(patientConnectionRepositoryProvider);
  return repository.getLinkedCaregivers();
});

final linkedCaregiversStreamProvider =
    StreamProvider.autoDispose<List<Caregiver>>((ref) async* {
  final repository = ref.watch(patientConnectionRepositoryProvider);
  yield* repository.getLinkedCaregiversStream();
});

// -----------------------------------------------------------------------------
// CAREGIVER SIDE: Connected Patients
// -----------------------------------------------------------------------------

final linkedPatientsProvider =
    FutureProvider.autoDispose<List<Patient>>((ref) async {
  final repository = ref.watch(patientConnectionRepositoryProvider);
  return repository.getConnectedPatients();
});

final linkedPatientsStreamProvider =
    StreamProvider.autoDispose<List<Patient>>((ref) {
  final repository = ref.watch(patientConnectionRepositoryProvider);
  return repository.getConnectedPatientsStream();
});

// Note: Profile photo upload is now handled by ProfilePhotoUploadNotifier
// in lib/providers/profile_photo_provider.dart


// Note: patientProfileProvider is now defined in 
// lib/screens/patient/profile/viewmodels/patient_profile_viewmodel.dart

