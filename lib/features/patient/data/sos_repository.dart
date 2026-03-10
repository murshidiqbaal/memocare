import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../providers/service_providers.dart';

final patientSosRepositoryProvider = Provider<PatientSosRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PatientSosRepository(supabase);
});

class PatientSosRepository {
  final SupabaseClient _supabase;
  static const _tableName = 'sos_messages';

  PatientSosRepository(this._supabase);

  Future<void> sendSOSAlert({String? note}) async {
    final patientId = _supabase.auth.currentUser?.id;
    if (patientId == null) throw Exception('User not authenticated');

    // 1. Fetch linked caregiver ID
    final links = await _supabase
        .from('caregiver_patient_links')
        .select('caregiver_id')
        .eq('patient_id', patientId)
        .maybeSingle();

    final caregiverId = links?['caregiver_id'];

    // 2. Get current position
    Position? position;
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      // If location fails, we still send the SOS without it
    }

    // 3. Insert into sos_messages
    await _supabase.from(_tableName).insert({
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'location_lat': position?.latitude,
      'location_lng': position?.longitude,
      'triggered_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'note': note,
    });
  }
}
