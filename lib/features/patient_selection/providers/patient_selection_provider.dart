import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/patient_model.dart';

/// State class holds the UI values and fetched list
class PatientState {
  final List<Patient> linkedPatients;
  final Patient? selectedPatient;
  final bool isLoading;
  final String? errorMessage;

  bool get isPatientSelected =>
      selectedPatient != null && selectedPatient!.id.isNotEmpty;

  PatientState({
    this.linkedPatients = const [],
    this.selectedPatient,
    this.isLoading = false,
    this.errorMessage,
  });

  PatientState copyWith({
    List<Patient>? linkedPatients,
    Patient? selectedPatient,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PatientState(
      linkedPatients: linkedPatients ?? this.linkedPatients,
      selectedPatient: selectedPatient ?? this.selectedPatient,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Provider to access PatientSelectionController globally
final patientSelectionProvider =
    StateNotifierProvider<PatientSelectionController, PatientState>((ref) {
  return PatientSelectionController(Supabase.instance.client);
});

class PatientSelectionController extends StateNotifier<PatientState> {
  final SupabaseClient _supabase;
  static const _selectedPatientKey = 'selected_patient_data';

  PatientSelectionController(this._supabase) : super(PatientState()) {
    _init();
  }

  Future<void> _init() async {
    // 1. Immediately restore from SharedPreferences (Optimistic loading)
    await _restorePersistedPatient();

    // 2. Fetch fresh list from Supabase
    await fetchLinkedPatients();
  }

  /// Restores the globally selected patient from local storage on app start
  Future<void> _restorePersistedPatient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientJsonStr = prefs.getString(_selectedPatientKey);

      if (patientJsonStr != null && patientJsonStr.isNotEmpty) {
        final decoded = jsonDecode(patientJsonStr) as Map<String, dynamic>;
        final restoredPatient = Patient.fromJson(decoded);
        state = state.copyWith(selectedPatient: restoredPatient);
      }
    } catch (e) {
      print('Error restoring persisted patient: $e');
    }
  }

  /// Saves selected patient info locally so it persists across app restarts
  Future<void> _persistSelectedPatient(Patient patient) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientJsonStr = jsonEncode(patient.toJson());
      await prefs.setString(_selectedPatientKey, patientJsonStr);
    } catch (e) {
      print('Error persisting selected patient: $e');
    }
  }

  /// Updates global state and saves to persistence
  void setSelectedPatient(Patient patient) {
    if (state.selectedPatient?.id == patient.id) return;
    state = state.copyWith(selectedPatient: patient);
    _persistSelectedPatient(patient);
  }

  /// Fetches the patients linked to the currently logged in caregiver
  Future<void> fetchLinkedPatients() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      state = state.copyWith(
          errorMessage: 'User not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Get caregiver id first
      final caregiverData = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (caregiverData == null) {
        state = state.copyWith(isLoading: false, linkedPatients: []);
        return;
      }
      final String caregiverId = caregiverData['id'];

      // 2. Fetch linked patients via caregiver_patient_links joining with patient_profiles
      final response = await _supabase
          .from('caregiver_patient_links')
          .select('patient_id, patient_profiles(*)')
          .eq('caregiver_id', caregiverId);

      final List<dynamic> records = response as List<dynamic>;

      final List<Patient> fetchedPatients = records.map((record) {
        return Patient.fromSupabase(record as Map<String, dynamic>);
      }).toList();

      Patient? newSelectedPatient = state.selectedPatient;

      // Ensure our selection is still valid in the new fetched list, else fallback to first or null
      if (fetchedPatients.isNotEmpty) {
        final validSelection =
            fetchedPatients.any((p) => p.id == newSelectedPatient?.id);
        if (!validSelection) {
          newSelectedPatient = fetchedPatients.first;
          _persistSelectedPatient(newSelectedPatient);
        }
      } else {
        newSelectedPatient = null;
      }

      state = state.copyWith(
        linkedPatients: fetchedPatients,
        selectedPatient: newSelectedPatient,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch patients: $e',
      );
    }
  }
}
