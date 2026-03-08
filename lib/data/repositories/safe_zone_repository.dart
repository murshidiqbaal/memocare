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

  Future<void> upsertSafeZone({
    required String patientId,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String label = 'Home',
  }) async {
    try {
      await _supabase.from('safe_zones').upsert({
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'label': label,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'patient_id');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SafeZoneRepository upsertSafeZone error: $e');
      }
      throw Exception('Failed to save home location. Please try again.');
    }
  }

  Future<List<String>> getLinkedCaregiversFcmTokens(String patientId) async {
    try {
      final response = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver:caregivers(user_id, fcm_token)')
          .eq('patient_id', patientId);

      final tokens = (response as List)
          .map((row) => row['caregiver']['fcm_token'] as String?)
          .where((token) => token != null && token.isNotEmpty)
          .cast<String>()
          .toList();

      return tokens;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SafeZoneRepository getLinkedCaregiversFcmTokens error: $e');
      }
      return [];
    }
  }

  Future<void> insertSafeZoneAlert({
    required String patientId,
    required double latitude,
    required double longitude,
    required String alertType,
  }) async {
    try {
      await _supabase.from('safezone_alerts').insert({
        'patient_id': patientId,
        'latitude': latitude,
        'longitude': longitude,
        'alert_type': alertType,
        'triggered_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SafeZoneRepository insertSafeZoneAlert error: $e');
      }
    }
  }
}
