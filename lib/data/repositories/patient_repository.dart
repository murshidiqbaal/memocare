import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient.dart';

class PatientRepository {
  final SupabaseClient _supabase;

  PatientRepository(this._supabase);

  /// Creates a primary patient record and returns the new patient ID (UUID).
  /// This ensures sequential creation to avoid foreign key errors.
  Future<String> createPatient({
    required String name,
    int? age,
    String? condition,
  }) async {
    try {
      // 1. Create a profile entry first if the schema requires it (patients references profiles)
      // Note: In some versions of this schema, patients.id references profiles.id.
      // However, for simplified "patient-only" creation as requested, we insert into patients.

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('patients')
          .insert({
            'user_id': userId,
            'full_name': name,
            'age': age,
            'condition': condition,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      if (e is PostgrestException && e.code == '23503') {
        throw Exception(
            'Schema violation: Ensure profile exists before patient creation. $e');
      }
      throw Exception('Failed to create patient: $e');
    }
  }

  /// Get or auto-create a patient profile for [userId].
  ///
  /// Queries `patients` by `user_id`. If no row is found, inserts one and
  /// returns the generated id. Prevents FK crashes when the row is missing.
  Future<String> getOrCreatePatientProfile(String userId) async {
    try {
      final existing = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) return existing['id'] as String;

      // Row missing — auto-create.
      final user = _supabase.auth.currentUser;
      final fullName =
          user?.userMetadata?['full_name'] as String? ?? 'Patient';
      debugPrint('[PatientRepo] Auto-creating patients row for $userId');
      final response = await _supabase
          .from('patients')
          .insert({
            'user_id': userId,
            'full_name': fullName,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final newId = response['id'] as String;
      debugPrint('[PatientRepo] Created patients id=$newId for $userId');
      return newId;
    } catch (e) {
      throw Exception('Failed to get/create patient profile: $e');
    }
  }

  /// Links an existing patient to a caregiver.
  /// Handles UUID conversion and validates caregiver existence.
  Future<void> linkPatientToCaregiver({
    required String patientId,
    required String caregiverUserId,
  }) async {
    try {
      // 1. Get the caregiver primary key (uuid) from profiles
      final caregiverProfile = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', caregiverUserId)
          .maybeSingle();

      if (caregiverProfile == null) {
        throw Exception(
            'Caregiver profile not found for user: $caregiverUserId');
      }
      final String caregiverId = caregiverProfile['id'];
      // 2. Insert into caregiver_patient_links
      print('Linking Patient ($patientId) to Caregiver ($caregiverId)');
      await _supabase.from('caregiver_patient_links').insert({
        'caregiver_id': caregiverId,
        'patient_id': patientId,
        'created_at': DateTime.now().toIso8601String(),
        'linked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to link patient: $e');
    }
  }

  /// Connects the current caregiver to a patient using an invite code.
  /// 1. Ensures caregiver profile exists to avoid FK errors.
  /// 2. Finds patient by invite code.
  /// 3. Checks for duplicates.
  /// 4. Creates the link.
  Future<void> connectPatientWithInviteCode(String inviteCode) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      // 1. Ensure Caregiver Profile exists (Avoid FK error)
      final caregiverRes = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      String caregiverId;
      if (caregiverRes == null) {
        final fullName =
            user.userMetadata?['full_name'] as String? ?? 'Caregiver';
        final insertRes = await _supabase
            .from('caregiver_profiles')
            .insert({
              'user_id': user.id,
              'full_name': fullName,
            })
            .select('id')
            .single();
        caregiverId = insertRes['id'] as String;
      } else {
        caregiverId = caregiverRes['id'] as String;
      }

      // 2. Find Patient by invite code
      final patientRes = await _supabase
          .from('patients')
          .select('id')
          .eq('invite_code', inviteCode.trim())
          .maybeSingle();

      if (patientRes == null) {
        throw Exception('Invalid invite code. Patient not found.');
      }
      final String patientId = patientRes['id'];

      // 3. Check for existing link (Prevent duplicates)
      final existingLink = await _supabase
          .from('caregiver_patient_links')
          .select('id')
          .eq('caregiver_id', caregiverId)
          .eq('patient_id', patientId)
          .maybeSingle();

      if (existingLink != null) {
        throw Exception('You are already connected to this patient.');
      }

      // 4. Create the link
      print('Connecting Caregiver ($caregiverId) to Patient ($patientId) via Invite');
      await _supabase.from('caregiver_patient_links').insert({
        'caregiver_id': caregiverId,
        'patient_id': patientId,
        'created_at': DateTime.now().toIso8601String(),
        'linked_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Database error: ${e.message}');
      }
      rethrow;
    }
  }

  /// Fetches all patients linked to a specific caregiver with a single join query.
  Future<List<Patient>> getPatientsForCaregiver(String caregiverUserId) async {
    try {
      // 1. Get caregiver id first
      final caregiverProfile = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', caregiverUserId)
          .maybeSingle();

      if (caregiverProfile == null) return [];
      final String caregiverId = caregiverProfile['id'];

      // 2. Optimized Join Query
      final List<dynamic> response =
          await _supabase.from('caregiver_patient_links').select('''
            linked_at,
            patients (*)
          ''').eq('caregiver_id', caregiverId);

      return response.map((row) {
        final patientData = row['patients'] as Map<String, dynamic>;

        return Patient.fromJson({
          ...patientData,
          'linked_at': row['linked_at'],
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch dashboard patients: $e');
    }
  }

  /// Fetches the auth user ID of the caregiver linked to a patient.
  Future<String?> getCaregiverUserId(String patientId) async {
    try {
      // 1. Get the caregiver(s) linked to this patient via the junction table
      final response = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id(user_id)')
          .eq('patient_id', patientId)
          .maybeSingle();

      if (response == null || response['caregiver_id'] == null) {
        return null;
      }

      final profile = response['caregiver_id'] as Map<String, dynamic>;
      return profile['user_id'] as String?;
    } catch (e) {
      debugPrint('[PatientRepo] Error fetching caregiver user ID: $e');
      return null;
    }
  }
}
