import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient.dart';

class PatientConnectionRepository {
  final SupabaseClient _supabase;

  PatientConnectionRepository(this._supabase);

  /// Fetch list of connected patients for the current caregiver
  Future<List<Patient>> getConnectedPatients() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // 1. Get caregiver id first
      final caregiverData = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (caregiverData == null) return [];
      final caregiverId = caregiverData['id'];

      // 2. Get linked patients with details
      // Fetch directly from 'patients' table as requested
      final List<dynamic> data = await _supabase.from('patients').select('''
            *,
            caregiver_patient_links!inner(
              caregiver_id,
              linked_at
            )
          ''').eq('caregiver_patient_links.caregiver_id', caregiverId);

      return data.map((json) {
        // Extract linked_at from the link array (which will have 1 item due to filter)
        final links = (json['caregiver_patient_links'] as List<dynamic>?) ?? [];
        final linkedAt = links.isNotEmpty ? links.first['linked_at'] : null;

        return Patient.fromJson({
          ...json,
          'linked_at': linkedAt,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch connected patients: $e');
    }
  }

  /// Real-time stream of connected patients
  Stream<List<Patient>> getConnectedPatientsStream() async* {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      // 1. Get caregiver ID
      final caregiverData = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (caregiverData == null) {
        yield [];
        return;
      }
      final String caregiverId = caregiverData['id'];

      // 2. Yield initial data
      yield await getConnectedPatients();

      // 3. Listen to changes
      final stream = _supabase
          .from('caregiver_patient_links')
          .stream(primaryKey: ['id']).eq('caregiver_id', caregiverId);

      // 4. On any change, refetch full details (with joins)
      await for (final _ in stream) {
        yield await getConnectedPatients();
      }
    } catch (e) {
      // Stream error handling: just yield empty or rethrow?
      // Rethrowing ends the stream.
      throw Exception('Stream error: $e');
    }
  }

  /// Connect using an invite code
  /// Logic: Read code -> validate -> insert link -> mark code used
  Future<void> connectUsingInviteCode(String code) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // 1. Get caregiver ID
      final caregiverData = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (caregiverData == null) {
        throw Exception('Please set up your caregiver profile first');
      }
      final String caregiverId = caregiverData['id'];

      // 2. Find and validate the invite code
      final response = await _supabase
          .from('invite_codes')
          .select('patient_id, expires_at, used')
          .eq('code', code)
          .maybeSingle();

      if (response == null) {
        throw Exception('Invalid invite code');
      }

      final String patientId = response['patient_id'];
      final DateTime expiresAt = DateTime.parse(response['expires_at']);
      final bool used = response['used'] as bool;

      if (used) {
        throw Exception('This code has already been used');
      }

      if (DateTime.now().isAfter(expiresAt)) {
        throw Exception('This code has expired');
      }

      // 3. Connect (transaction-like sequence)
      // Note: We perform updates and inserts. If one fails, the error propagates.

      // Check for existing link
      final existing = await _supabase
          .from('caregiver_patient_links')
          .select('id')
          .eq('caregiver_id', caregiverId)
          .eq('patient_id', patientId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('You are already connected to this patient');
      }

      // Link caregiver and patient
      await _supabase.from('caregiver_patient_links').insert({
        'caregiver_id': caregiverId,
        'patient_id': patientId,
        'linked_at': DateTime.now().toIso8601String(),
      });

      // Mark code as used
      await _supabase
          .from('invite_codes')
          .update({'used': true}).eq('code', code);
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Remove a connection
  Future<void> removeConnection(String patientId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final caregiverData = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (caregiverData == null) return;
      final caregiverId = caregiverData['id'];

      await _supabase
          .from('caregiver_patient_links')
          .delete()
          .eq('caregiver_id', caregiverId)
          .eq('patient_id', patientId);
    } catch (e) {
      throw Exception('Failed to remove connection: $e');
    }
  }
}
