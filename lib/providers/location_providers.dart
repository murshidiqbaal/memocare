import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/patient_home_location.dart';
import '../data/models/patient_live_location.dart';
import '../data/repositories/location_repository.dart';
import '../providers/service_providers.dart';

/// Provider for location repository instance
final locationRepositoryProvider = Provider((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return LocationRepository(supabase);
});

/// Realtime patient live location provider
final patientLiveLocationProvider = StreamProvider.autoDispose
    .family<PatientLiveLocation?, String>((ref, patientId) {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.watchPatientLiveLocation(patientId);
});

/// Provider for patient home location (safe zone)
final patientHomeLocationProvider =
    FutureProvider.family<PatientHomeLocation?, String>((ref, patientId) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getPatientHomeLocation(patientId);
});
