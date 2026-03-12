import 'package:memocare/features/linking/data/models/caregiver_patient_link.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ConnectionRepository {
  final SupabaseClient _supabase;

  ConnectionRepository(this._supabase);

  /// Connect to a patient using an invite code
  Future<void> connectToPatient(String code) async {
    final userId = _supabase.auth.currentUser!.id;

    // 0. Get Correct Caregiver ID (profiles.id)
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

    // 3. Create the secure link
    print('Linking Caregiver ($caregiverId) to Patient ($patientId)');

    await _supabase.from('caregiver_patient_links').insert({
      'caregiver_id': caregiverId,
      'patient_id': patientId,
      'created_at': DateTime.now().toIso8601String(),
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
        .select('*, patients:patient_id(full_name)')
        .eq('caregiver_id', caregiverId);

    return data.map((json) {
      final patient = json['patients'] as Map<String, dynamic>?;
      return CaregiverPatientLink.fromJson({
        ...json,
        'patient_name': patient?['full_name'],
      });
    }).toList();
  }

  /// Get list of linked caregivers for a patient
  Future<List<CaregiverPatientLink>> getLinkedCaregivers() async {
    final authId = _supabase.auth.currentUser!.id;

    // Resolve internal patient ID
    final patientRow = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', authId)
        .maybeSingle();

    if (patientRow == null) return [];
    final String patientId = patientRow['id'];

    final List<dynamic> data = await _supabase
        .from('caregiver_patient_links')
        .select('*, caregiver_profiles:caregiver_id(full_name)')
        .eq('patient_id', patientId);

    return data.map((json) {
      final caregiver = json['caregiver_profiles'] as Map<String, dynamic>?;
      return CaregiverPatientLink.fromJson({
        ...json,
        'caregiver_name': caregiver?['full_name'],
      });
    }).toList();
  }
}
