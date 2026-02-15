import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/caregiver_patient_link.dart';
import '../data/repositories/connection_repository.dart';
import 'service_providers.dart';

final connectionRepositoryProvider = Provider<ConnectionRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ConnectionRepository(supabase);
});

/// Providers for Caregiver view
final linkedPatientsProvider =
    FutureProvider<List<CaregiverPatientLink>>((ref) {
  return ref.watch(connectionRepositoryProvider).getLinkedPatients();
});

/// Providers for Patient view
// incomingRequestsProvider removed as we use instant invite codes now

final linkedCaregiversProvider =
    FutureProvider<List<CaregiverPatientLink>>((ref) {
  return ref.watch(connectionRepositoryProvider).getLinkedCaregivers();
});
