import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver.dart';
import '../models/patient.dart';

/// Repository that handles all caregiver ↔ patient connection logic.
///
/// KEY SCHEMA NOTE
/// ───────────────
/// caregiver_patient_links.caregiver_id  →  profiles.id   (NOT auth.uid)
/// caregiver_patient_links.patient_id    →  patients.id   (NOT auth.uid)
///
/// Both tables have a `user_id` column that links to auth.users.id.
/// We must resolve the profile/patient row ID before querying the links table.
class PatientConnectionRepository {
  final SupabaseClient _supabase;
  static const _linksTable = 'caregiver_patient_links';

  PatientConnectionRepository(this._supabase);

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Resolve `profiles.id` for the current authenticated user.
  Future<String?> _resolveCaregiverId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final row = await _supabase
          .from('caregiver_profiles')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return row?['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Resolve `patients.id` for the current authenticated user (patient side).
  Future<String?> _resolvePatientId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final row = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return row?['id'] as String?;
    } catch (e) {
      return null;
    }
  }

  // ── Caregiver side ─────────────────────────────────────────────────────────

  /// Fetch all patients linked to the current caregiver.
  Future<List<Patient>> getConnectedPatients() async {
    try {
      final caregiverId = await _resolveCaregiverId();
      if (caregiverId == null) return [];

      final List<dynamic> rows = await _supabase.from(_linksTable).select('''
            linked_at,
            patient:patients (
              id,
              user_id,
              full_name,
              profile_photo_url,
              age,
              condition,
              gender,
              phone_number,
              date_of_birth,
              emergency_contact_phone
            )
          ''').eq('caregiver_id', caregiverId);

      return rows.where((r) => r['patient'] != null).map((r) {
        final patientJson =
            Map<String, dynamic>.from(r['patient'] as Map<String, dynamic>);
        if (r['linked_at'] != null) {
          patientJson['linked_at'] = r['linked_at'];
        }
        return Patient.fromJson(patientJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch connected patients: $e');
    }
  }

  /// Real-time stream: re-emits the patient list whenever the link table changes.
  Stream<List<Patient>> getConnectedPatientsStream() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    yield await getConnectedPatients();

    final caregiverId = await _resolveCaregiverId();
    if (caregiverId == null) return;

    final stream = _supabase
        .from(_linksTable)
        .stream(primaryKey: ['id']).eq('caregiver_id', caregiverId);

    await for (final _ in stream) {
      yield await getConnectedPatients();
    }
  }

  // ── Patient side ───────────────────────────────────────────────────────────

  /// Fetch all caregivers linked to the current patient.
  Future<List<Caregiver>> getLinkedCaregivers() async {
    try {
      final patientId = await _resolvePatientId();
      if (patientId == null) return [];

      // Query caregiver_patient_links and join with profiles table
      final List<dynamic> rows = await _supabase.from(_linksTable).select('''
            relationship,
            caregiver_profiles!caregiver_id (
              id,
              user_id,
              full_name,
              phone,
              profile_photo_url,
              created_at
            )
          ''').eq('patient_id', patientId);

      return rows
          .where((r) => r['caregiver_profiles'] != null)
          .map((r) => Caregiver.fromJson(
                Map<String, dynamic>.from(r as Map<String, dynamic>),
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch linked caregivers: $e');
    }
  }

  /// Real-time stream of caregivers linked to the patient.
  Stream<List<Caregiver>> getLinkedCaregiversStream() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    yield await getLinkedCaregivers();

    final patientId = await _resolvePatientId();
    if (patientId == null) return;

    final stream = _supabase
        .from(_linksTable)
        .stream(primaryKey: ['id']).eq('patient_id', patientId);

    await for (final _ in stream) {
      yield await getLinkedCaregivers();
    }
  }

  // ── Connection actions ─────────────────────────────────────────────────────

  /// Connect a caregiver to a patient using an invite code.
  Future<void> connectUsingInviteCode(String code) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final caregiverId = await _resolveCaregiverId();
    if (caregiverId == null) {
      throw Exception(
          'No caregiver profile found. Please complete your profile first.');
    }

    final invite = await _supabase
        .from('invite_codes')
        .select('patient_id, expires_at, used')
        .eq('code', code.trim())
        .maybeSingle();

    if (invite == null) throw Exception('Invalid invite code');
    if (invite['used'] == true) throw Exception('Code already used');

    final expiresAt = DateTime.parse(invite['expires_at'] as String);
    if (DateTime.now().isAfter(expiresAt)) throw Exception('Code has expired');

    final String patientId = invite['patient_id'] as String;

    final existing = await _supabase
        .from(_linksTable)
        .select('id')
        .eq('caregiver_id', caregiverId)
        .eq('patient_id', patientId)
        .maybeSingle();

    if (existing != null) throw Exception('Already connected to this patient');

    await Future.wait([
      _supabase.from(_linksTable).insert({
        'caregiver_id': caregiverId,
        'patient_id': patientId,
        'created_at': DateTime.now().toIso8601String(),
        'linked_at': DateTime.now().toIso8601String(),
      }),
      _supabase.from('invite_codes').update({'used': true}).eq('code', code),
    ]);
  }

  /// Remove the link between the current caregiver and a patient.
  Future<void> removeConnection(String patientId) async {
    final caregiverId = await _resolveCaregiverId();
    if (caregiverId == null) return;

    await _supabase
        .from(_linksTable)
        .delete()
        .eq('caregiver_id', caregiverId)
        .eq('patient_id', patientId);
  }
}
