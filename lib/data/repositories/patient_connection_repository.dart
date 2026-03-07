import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver.dart';
import '../models/patient.dart';

class PatientConnectionRepository {
  final SupabaseClient _supabase;
  static const _linksTable = 'caregiver_patient_links';

  PatientConnectionRepository(this._supabase);

  /// Fetch list of connected patients for the current caregiver
  /// Logic: Query the link table, join patients and their profiles.
  Future<List<Patient>> getConnectedPatients() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Query caregiver_patient_links joined with patients and profiles
      final List<dynamic> response =
          await _supabase.from(_linksTable).select('''
            linked_at,
            patients (
              *,
              profiles (*)
            )
          ''').eq('caregiver_id', user.id);

      return response
          .map((data) => Patient.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch connected patients: $e');
    }
  }

  /// Real-time stream of connected patients for the caregiver
  /// Strategy: Refetch full details whenever the link table changes for this caregiver.
  Stream<List<Patient>> getConnectedPatientsStream() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    // Initial fetch
    yield await getConnectedPatients();

    // Listen to changes in the link table
    final stream = _supabase
        .from(_linksTable)
        .stream(primaryKey: ['id']).eq('caregiver_id', user.id);

    await for (final _ in stream) {
      yield await getConnectedPatients();
    }
  }

  /// Get linked caregivers for the current patient
  Future<List<Caregiver>> getLinkedCaregivers() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Query caregiver_patient_links joined with profiles (caregiver details)
      final List<dynamic> response =
          await _supabase.from(_linksTable).select('''
            relationship,
            profiles (*)
          ''').eq('patient_id', user.id);

      return response
          .map((data) => Caregiver.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch linked caregivers: $e');
    }
  }

  /// Real-time stream of linked caregivers for the patient
  Stream<List<Caregiver>> getLinkedCaregiversStream() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    yield await getLinkedCaregivers();

    final stream = _supabase
        .from(_linksTable)
        .stream(primaryKey: ['id']).eq('patient_id', user.id);

    await for (final _ in stream) {
      yield await getLinkedCaregivers();
    }
  }

  // --- Connection Actions ---

  /// Connect using an invite code
  Future<void> connectUsingInviteCode(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. Find and validate the invite code
      final response = await _supabase
          .from('invite_codes')
          .select('patient_id, expires_at, used')
          .eq('code', code)
          .maybeSingle();

      if (response == null) throw Exception('Invalid invite code');
      if (response['used'] == true) throw Exception('Code already used');

      final expiresAt = DateTime.parse(response['expires_at']);
      if (DateTime.now().isAfter(expiresAt)) throw Exception('Code expired');

      final String patientId = response['patient_id'];

      // 2. Check existing connection
      final existing = await _supabase
          .from(_linksTable)
          .select('id')
          .eq('caregiver_id', user.id)
          .eq('patient_id', patientId)
          .maybeSingle();

      if (existing != null)
        throw Exception('Already connected to this patient');

      // 3. Perform link and mark code used
      await _supabase.from(_linksTable).insert({
        'caregiver_id': user.id,
        'patient_id': patientId,
      });

      await _supabase
          .from('invite_codes')
          .update({'used': true}).eq('code', code);
    } catch (e) {
      rethrow;
    }
  }

  /// Remove a connection between a caregiver and patient
  Future<void> removeConnection(String patientId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase
        .from(_linksTable)
        .delete()
        .eq('caregiver_id', user.id)
        .eq('patient_id', patientId);
  }
}
