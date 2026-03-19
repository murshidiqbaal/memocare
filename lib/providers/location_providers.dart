import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/location_alert.dart';
import '../data/models/patient_location.dart';
import '../data/models/safe_zone.dart';
import '../data/repositories/safe_zone_repository.dart';
import '../features/sos/data/repositories/sos_system_repository.dart';
import '../providers/service_providers.dart';

/// Provider for location repository instance (now points to safe zone repo for home)
final locationRepositoryProvider = Provider((ref) {
  return ref.watch(safeZoneRepositoryProvider);
});

/// Realtime patient live location provider (using patient_locations table)
final patientLiveLocationProvider = StreamProvider.autoDispose
    .family<PatientLocation?, String>((ref, patientId) {
  final repository = ref.watch(sosSystemRepositoryProvider);
  return repository.streamPatientLocation(patientId);
});

/// Provider for patient home location (safe zone)
final patientHomeLocationProvider =
    FutureProvider.family<SafeZone?, String>((ref, patientId) async {
  final repository = ref.watch(safeZoneRepositoryProvider);
  return repository.getPatientSafeZone(patientId);
});

/// Realtime location alerts provider for caregiver
final realtimeLocationAlertsProvider = StreamProvider.autoDispose
    .family<List<LocationAlert>, String>((ref, caregiverId) {
  final supabase = ref.watch(supabaseClientProvider);
  return supabase
      .from('location_alerts')
      .stream(primaryKey: ['id'])
      .eq('caregiver_id', caregiverId)
      .order('created_at', ascending: false)
      .map((data) =>
          data.map((json) => LocationAlert.fromJson(json)).toList());
});
