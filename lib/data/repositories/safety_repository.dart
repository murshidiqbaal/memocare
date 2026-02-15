import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/sos_event.dart';

class SafetyRepository {
  final SupabaseClient _supabase;

  SafetyRepository(this._supabase);

  // Trigger SOS event
  Future<void> sendSos({required double? lat, required double? lon}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now().toUtc();
    // Using `returning` to get ID if desired, usually auto-gen.
    await _supabase.from('sos_events').insert({
      'patient_id': user.id,
      'triggered_at': now.toIso8601String(),
      'is_active': true,
      'latitude': lat,
      'longitude': lon,
    });
  }

  // Fetch active alerts for linked patients (Caregiver Only)
  Future<List<SosEvent>> getActiveAlerts(List<String> patientIds) async {
    if (patientIds.isEmpty) return [];

    final response = await _supabase
        .from('sos_events')
        .select()
        .filter('patient_id', 'in', patientIds)
        .eq('is_active', true)
        .order('triggered_at', ascending: false);

    return (response as List).map((json) => SosEvent.fromJson(json)).toList();
  }

  // Resolve alert
  Future<void> resolveAlert(String alertId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('sos_events').update({
      'is_active': false,
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': user.id,
    }).eq('id', alertId);
  }
}
