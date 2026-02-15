import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/caregiver_patient_link.dart';
import '../models/invite_code.dart';

class LinkRepository {
  final SupabaseClient _supabase;

  LinkRepository(this._supabase);

  // --- Patient Methods ---

  Future<InviteCode?> getActiveInviteCode(String patientId) async {
    final data = await _supabase
        .from('invite_codes')
        .select()
        .eq('patient_id', patientId)
        .eq('used', false)
        .gt('expires_at', DateTime.now().toIso8601String());

    if (data.isEmpty) return null;
    return InviteCode.fromJson(data.first);
  }

  Future<InviteCode> generateInviteCode(String patientId) async {
    final code = _generateRandomCode();
    final expiresAt = DateTime.now().add(const Duration(hours: 48));

    // Delete any existing active unused codes for this patient to prevent clutter
    await _supabase
        .from('invite_codes')
        .delete()
        .eq('patient_id', patientId)
        .eq('used', false);

    final data = await _supabase
        .from('invite_codes')
        .insert({
          'patient_id': patientId,
          'code': code,
          'expires_at': expiresAt.toIso8601String(),
          'used': false,
        })
        .select()
        .single();

    return InviteCode.fromJson(data);
  }

  Future<List<CaregiverPatientLink>> getLinkedCaregivers(
      String patientId) async {
    // Determine table relationship. Assuming 'profiles' is linked via 'caregiver_id'
    final data = await _supabase
        .from('caregiver_patients')
        .select('*, related_profile:profiles!caregiver_id(*)')
        .eq('patient_id', patientId);

    return (data as List).map((e) => CaregiverPatientLink.fromJson(e)).toList();
  }

  Future<void> removeCaregiver(String linkId) async {
    await _supabase.from('caregiver_patients').delete().eq('id', linkId);
  }

  // --- Caregiver Methods ---

  Future<void> linkPatient(String caregiverId, String inviteCode) async {
    // Ideally use an RPC for atomicity: await _supabase.rpc('redeem_invite', {'code': inviteCode, 'caregiver_uid': caregiverId});

    // Client-side implementation (Subject to RLS and Race Conditions, but acceptable for MVP)

    // 1. Verify Code
    final codes = await _supabase
        .from('invite_codes')
        .select()
        .eq('code', inviteCode)
        .eq('used', false)
        .gt('expires_at', DateTime.now().toIso8601String());

    if (codes.isEmpty) {
      throw Exception('Invalid or expired invite code.');
    }

    final codeData = codes.first;
    final patientId = codeData['patient_id'];

    if (patientId == caregiverId) {
      throw Exception('You cannot link to yourself.');
    }

    // 2. Check if already linked
    final existingLinks = await _supabase
        .from('caregiver_patients')
        .select()
        .eq('caregiver_id', caregiverId)
        .eq('patient_id', patientId);

    if (existingLinks.isNotEmpty) {
      throw Exception('You are already linked to this patient.');
    }

    // 3. Create Link
    await _supabase.from('caregiver_patients').insert({
      'caregiver_id': caregiverId,
      'patient_id': patientId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // 4. Mark code used
    await _supabase
        .from('invite_codes')
        .update({'used': true}).eq('id', codeData['id']);
  }

  Future<List<CaregiverPatientLink>> getLinkedPatients(
      String caregiverId) async {
    // Determine table relationship. Assuming 'profiles' is linked via 'patient_id'
    final data = await _supabase
        .from('caregiver_patients')
        .select('*, related_profile:profiles!patient_id(*)')
        .eq('caregiver_id', caregiverId);

    return (data as List).map((e) => CaregiverPatientLink.fromJson(e)).toList();
  }

  String _generateRandomCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I, O, 0, 1 for clarity
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6,
      (_) => chars.codeUnitAt(rnd.nextInt(chars.length)),
    ));
  }
}

final linkRepositoryProvider = Provider<LinkRepository>((ref) {
  return LinkRepository(Supabase.instance.client);
});
