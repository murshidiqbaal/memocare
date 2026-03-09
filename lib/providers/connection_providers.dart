import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/caregiver.dart';
import '../data/models/patient.dart';
import 'service_providers.dart';

// =============================================================================
// PATIENT SIDE — CAREGIVERS LINKED TO A PATIENT
// =============================================================================

/// Fetch caregivers connected to the current patient (one-time request)
final linkedCaregiversProvider =
    FutureProvider.autoDispose<List<Caregiver>>((ref) async {
  final repository = ref.watch(patientConnectionRepositoryProvider);

  final caregivers = await repository.getLinkedCaregivers();
  return caregivers;
});

/// Real-time stream of caregivers linked to the patient
final linkedCaregiversStreamProvider =
    StreamProvider.autoDispose<List<Caregiver>>((ref) {
  final repository = ref.watch(patientConnectionRepositoryProvider);

  return repository.getLinkedCaregiversStream();
});

// =============================================================================
// CAREGIVER SIDE — PATIENTS CONNECTED TO A CAREGIVER
// =============================================================================

/// Fetch patients connected to the current caregiver (one-time request)
final linkedPatientsProvider =
    FutureProvider.autoDispose<List<Patient>>((ref) async {
  final repository = ref.watch(patientConnectionRepositoryProvider);

  final patients = await repository.getConnectedPatients();
  return patients;
});

/// Real-time stream of patients connected to the caregiver
final linkedPatientsStreamProvider =
    StreamProvider.autoDispose<List<Patient>>((ref) {
  final repository = ref.watch(patientConnectionRepositoryProvider);

  return repository.getConnectedPatientsStream();
});

// =============================================================================
// NOTES
// =============================================================================

// Profile photo upload handled in:
// lib/providers/profile_photo_provider.dart

// Patient profile provider defined in:
// lib/screens/patient/profile/viewmodels/patient_profile_viewmodel.dart
