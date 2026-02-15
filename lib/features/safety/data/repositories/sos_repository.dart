import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/service_providers.dart'; // For supabaseClientProvider
import '../models/live_location.dart';
import '../models/sos_alert.dart';

class SosRepository {
  final SupabaseClient _supabase;

  SosRepository(this._supabase);

  // --- Patient Methods ---

  /// Trigger an SOS alert
  Future<SosAlert> createSosAlert(
      String patientId, double lat, double long) async {
    final response = await _supabase
        .from('sos_alerts')
        .insert({
          'patient_id': patientId,
          'latitude': lat,
          'longitude': long,
          'status': 'active',
        })
        .select()
        .single();

    return SosAlert.fromJson(response);
  }

  /// Update live location during an active SOS
  Future<void> updateLiveLocation(
      String patientId, double lat, double long) async {
    await _supabase.from('live_locations').insert({
      'patient_id': patientId,
      'latitude': lat,
      'longitude': long,
    });

    // Also update the latest position in the active alert itself for quick reference
    await _supabase
        .from('sos_alerts')
        .update({
          'latitude': lat,
          'longitude': long,
        })
        .eq('patient_id', patientId)
        .eq('status', 'active');
  }

  /// Get the active SOS alert if one exists for the patient
  Future<SosAlert?> getActiveAlert(String patientId) async {
    final response = await _supabase
        .from('sos_alerts')
        .select()
        .eq('patient_id', patientId)
        .eq('status', 'active')
        .maybeSingle();

    if (response == null) return null;
    return SosAlert.fromJson(response);
  }

  // --- Caregiver Methods ---

  /// Stream of active SOS alerts for linked patients
  /// Filtering by linked patients is handled by RLS on the server side.
  /// The query just asks for 'active' alerts that the user is allowed to see.
  Stream<List<SosAlert>> streamActiveAlerts() {
    return _supabase
        .from('sos_alerts')
        .stream(primaryKey: ['id'])
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => SosAlert.fromJson(json)).toList());
  }

  /// Resolve an SOS alert (mark as safe)
  Future<void> resolveSosAlert(String alertId) async {
    await _supabase.from('sos_alerts').update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  /// Stream live location updates for a specific patient
  Stream<List<LiveLocation>> streamLiveLocation(String patientId) {
    // We only need the latest location, but Supabase Realtime streams changes.
    // We can order by recorded_at descending and take 1.
    return _supabase
        .from('live_locations')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .map(
            (data) => data.map((json) => LiveLocation.fromJson(json)).toList());
  }
}

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SosRepository(supabase);
});
