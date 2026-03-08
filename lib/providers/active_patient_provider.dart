import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models/patient.dart';

final activePatientIdProvider =
    StateNotifierProvider<ActivePatientNotifier, String?>((ref) {
  return ActivePatientNotifier();
});

class ActivePatientNotifier extends StateNotifier<String?> {
  static const _key = 'active_patient_id';

  ActivePatientNotifier() : super(null) {
    _loadPersisted();
  }

  Future<void> _loadPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && state == null) {
      state = saved;
    }
  }

  void setActivePatient(String patientId) {
    if (state == patientId) return;
    state = patientId;
    _persist(patientId);
  }

  void clearActivePatient() {
    state = null;
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_key));
  }

  Future<void> _persist(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, patientId);
  }
}

final linkedPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser?.id;
  if (userId == null) return [];

  final caregiverRes = await supabase
      .from('caregiver_profiles')
      .select('id')
      .eq('user_id', userId)
      .maybeSingle();

  if (caregiverRes == null) return [];

  final List<dynamic> links = await supabase
      .from('caregiver_patient_links')
      .select('linked_at, patients!caregiver_patient_links_patient_fk(*)')
      .eq('caregiver_id', caregiverRes['id']);

  final patients = links.map((l) {
    final patientData = l['patients'] as Map<String, dynamic>;
    return Patient.fromJson({
      ...patientData,
      'linked_at': l['linked_at'],
    });
  }).toList();

  final activeId = ref.read(activePatientIdProvider);
  if (patients.isNotEmpty) {
    final isValid = patients.any((p) => p.id == activeId);
    if (activeId == null || !isValid) {
      // Microtask ensures state modification doesn't throw during Future build
      Future.microtask(() => ref
          .read(activePatientIdProvider.notifier)
          .setActivePatient(patients.first.id));
    }
  } else {
    if (activeId != null) {
      Future.microtask(() =>
          ref.read(activePatientIdProvider.notifier).clearActivePatient());
    }
  }

  return patients;
});
