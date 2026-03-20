import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memocare/data/models/user/patient_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import '../../../../data/models/patient_profile.dart';

/// 🔥 Unified realtime provider for Patient Profile.
/// - Caregiver → query by patient id
/// - Patient → query by auth user_id
final patientProfileProvider =
    StreamProvider.autoDispose.family<PatientProfile?, String?>(
  (ref, patientId) {
    final supabase = Supabase.instance.client;

    // 👀 Caregiver viewing specific patient
    if (patientId != null && patientId.isNotEmpty) {
      return supabase
          .from('patients')
          .stream(primaryKey: ['id'])
          .eq('id', patientId)
          .map(_mapSinglePatientSafely);
    }

    // 👤 Patient viewing own profile
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value(null);
    }

    return supabase
        .from('patients')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map(_mapSinglePatientSafely);
  },
);

PatientProfile? _mapSinglePatientSafely(List<Map<String, dynamic>> rows) {
  if (rows.isEmpty) return null;

  try {
    final firstRow = rows.first;
    // Extra safety: ensure primary key exists before parsing
    if (firstRow['id'] == null) return null;
    return PatientProfile.fromJson(firstRow);
  } catch (e) {
    debugPrint('PatientProfile mapping error: $e');
    return null;
  }
}

/// ✅ Linked caregivers provider (clean + typed)
final patientCaregiversProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, patientId) async {
    final supabase = Supabase.instance.client;

    if (patientId.isEmpty) return [];

  final data = await supabase
      .from('caregiver_patient_links')
      .select('*, caregiver_profiles(*)')
      .eq('patient_id', patientId)
      .order('linked_at');

  debugPrint("CARE LINKS RESULT: $data");

  return List<Map<String, dynamic>>.from(data);
});
