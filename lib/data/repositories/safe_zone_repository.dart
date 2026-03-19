import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../providers/supabase_provider.dart';
import '../models/safe_zone.dart';

final safeZoneRepositoryProvider = Provider<SafeZoneRepository>((ref) {
  return SafeZoneRepository(ref.watch(supabaseClientProvider));
});

class SafeZoneRepository {
  final SupabaseClient _supabase;
  static const _tableName = 'patient_home_locations';

  SafeZoneRepository(this._supabase);

  Future<SafeZone?> getPatientSafeZone(String patientId) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      if (response == null) return null;
      return SafeZone.fromJson(response);
    } catch (e) {
      print('Error getting safe zone: $e');
      return null;
    }
  }

  Stream<SafeZone?> streamPatientSafeZone(String patientId) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .limit(1)
        .map((data) => data.isEmpty ? null : SafeZone.fromJson(data.first));
  }

  Future<void> upsertSafeZone({
    required String patientId,
    required double homeLat,
    required double homeLng,
    required double radius,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    required String label,
  }) async {
    try {
      await _supabase.from(_tableName).upsert({
        'patient_id': patientId,
        'home_lat': homeLat,
        'home_lng': homeLng,
        'radius': radius,
      });
    } catch (e) {
      print('Error upserting safe zone: $e');
      rethrow;
    }
  }
}
