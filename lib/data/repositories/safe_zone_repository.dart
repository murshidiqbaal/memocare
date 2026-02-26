import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/safe_zone.dart';

class SafeZoneRepository {
  final SupabaseClient _supabase;

  SafeZoneRepository(this._supabase);

  Future<SafeZone?> getPatientSafeZone(String patientId) async {
    try {
      final response = await _supabase
          .from('safe_zones')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      if (response != null) {
        return SafeZone.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SafeZoneRepository getPatientSafeZone error: $e');
      }
      return null;
    }
  }

  Future<void> upsertSafeZone(SafeZone zone) async {
    try {
      await _supabase.from('safe_zones').upsert(
            zone.toJson(),
            onConflict: 'patient_id',
          );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SafeZoneRepository upsertSafeZone error: $e');
      }
      throw Exception('Failed to save home location. Please try again.');
    }
  }
}
