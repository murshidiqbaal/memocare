import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/patient.dart';
import 'connection_providers.dart' as connection_providers;

String requireActivePatientId(BuildContext context, WidgetRef ref) {
  final patientId = ref.read(activePatientIdProvider);
  if (patientId == null || patientId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No patient selected.'),
        backgroundColor: Colors.red,
      ),
    );
    throw Exception('No patient selected.');
  }
  return patientId;
}

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

/// This provider watches the generic linkedPatientsProvider and handles
/// auto-selecting the first patient if none is selected or selected is invalid.
final linkedPatientsProvider = FutureProvider<List<Patient>>((ref) async {
  // Watch the repository-backed list from connection_providers
  final patients =
      await ref.watch(connection_providers.linkedPatientsProvider.future);

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
