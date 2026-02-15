import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_patient_link.dart';

class ConnectionRepository {
  final SupabaseClient _supabase;

  ConnectionRepository(this._supabase);

  /// Connect to a patient using an invite code
  Future<void> connectToPatient(String code) async {
    final userId = _supabase.auth.currentUser!.id;

    // 0. Get Correct Caregiver ID
    final caregiverData = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (caregiverData == null) {
      throw Exception('Please set up your caregiver profile first');
    }
    final String caregiverId = caregiverData['id'];

    // 1. Find and validate the invite code
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
      throw Exception('This invite code has already been used');
    }

    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('This invite code has expired');
    }

    // 2. Check if already linked
    final existingLink = await _supabase
        .from('caregiver_patient_links')
        .select('id')
        .eq('caregiver_id', caregiverId)
        .eq('patient_id', patientId)
        .maybeSingle();

    if (existingLink != null) {
      throw Exception('You are already connected to this patient');
    }

    // 3. Create the secure link
    await _supabase.from('caregiver_patient_links').insert({
      'caregiver_id': caregiverId,
      'patient_id': patientId,
      'linked_at': DateTime.now().toIso8601String(),
    });

    // 4. Mark invite code as used
    await _supabase
        .from('invite_codes')
        .update({'used': true}).eq('code', code);
  }

  /// Get list of linked patients for a caregiver
  Future<List<CaregiverPatientLink>> getLinkedPatients() async {
    final userId = _supabase.auth.currentUser!.id;

    final caregiverData = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', userId)
        .maybeSingle();

    if (caregiverData == null) return [];
    final String caregiverId = caregiverData['id'];

    final List<dynamic> data = await _supabase
        .from('caregiver_patient_links')
        .select('*, profiles:patient_id(full_name, email)')
        .eq('caregiver_id', caregiverId);

    return data.map((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      return CaregiverPatientLink.fromJson({
        ...json,
        'patient_name': profile?['full_name'],
        'patient_email': profile?['email'],
      });
    }).toList();
  }

  /// Get list of linked caregivers for a patient
  Future<List<CaregiverPatientLink>> getLinkedCaregivers() async {
    final patientId = _supabase.auth.currentUser!.id;
    final List<dynamic> data = await _supabase
        .from('caregiver_patient_links')
        .select('*, profiles:caregiver_id(full_name, email)')
        .eq('patient_id', patientId);

    return data.map((json) {
      final profile = json['profiles'] as Map<String, dynamic>?;
      return CaregiverPatientLink.fromJson({
        ...json,
        'caregiver_name': profile?['full_name'],
        'caregiver_email': profile?['email'],
      });
    }).toList();
  }
}
