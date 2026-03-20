import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../providers/service_providers.dart';

final patientSosRepositoryProvider = Provider<PatientSosRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PatientSosRepository(supabase);
});

class PatientSosRepository {
  final SupabaseClient _supabase;
  static const _tableName = 'sos_messages';

  PatientSosRepository(this._supabase);

  Future<void> sendSOSAlert({String? note}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (kDebugMode) print("SOS DEBUG: No authenticated user found.");
      throw Exception('User not authenticated');
    }

    // --- STEP 1: Resolve internal patient_id (patients.id) ---
    // The schema expects patients.id, so we must resolve it from auth.users.id
    if (kDebugMode) print("SOS DEBUG resolve patient_id for auth_uid: ${user.id}");
    
    final patientResponse = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (patientResponse == null) {
      if (kDebugMode) print("SOS DEBUG ERROR: Patient profile not found for user ${user.id}");
      throw Exception('Patient profile not found');
    }

    final patientId = patientResponse['id'] as String;
    if (kDebugMode) print("SOS DEBUG resolved patient_id: $patientId");

    // --- STEP 2: Fetch linked caregiver_id ---
    if (kDebugMode) print("SOS DEBUG lookup caregiver for patient_id: $patientId");
    
    final link = await _supabase
        .from('caregiver_patient_links')
        .select('caregiver_id')
        .eq('patient_id', patientId)
        .maybeSingle();

    final caregiverId = link?['caregiver_id'] as String?;
    if (kDebugMode) {
      if (caregiverId != null) {
        print("SOS DEBUG found caregiver_id: $caregiverId");
      } else {
        print("SOS DEBUG WARNING: No linked caregiver found for this patient.");
      }
    }

    // --- STEP 3: Capture location safely ---
    double? lat;
    double? lng;
    try {
      if (kDebugMode) print("SOS DEBUG capturing location...");
      
      // Check/Request permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 3));
        
        lat = position.latitude;
        lng = position.longitude;
        if (kDebugMode) print("SOS DEBUG location captured: $lat, $lng");
      } else {
        if (kDebugMode) print("SOS DEBUG location denied, sending without coordinates.");
      }
    } catch (e) {
       if (kDebugMode) print("SOS DEBUG location lookup failed or timed out: $e");
    }

    // --- STEP 4 & 5: Correct insert query with debug logging ---
    final Map<String, dynamic> insertPayload = {
      'patient_id': patientId,
      'caregiver_id': caregiverId, // Can be null as per user requirement Step 2
      'lat': lat,
      'lng': lng,
      'triggered_at': DateTime.now().toUtc().toIso8601String(),
      'status': 'pending',
      'note': note ?? 'Manual Emergency SOS Alert',
    };

    if (kDebugMode) {
      print("SOS DEBUG patient_id: $patientId");
      print("SOS DEBUG caregiver_id: $caregiverId");
      print("SOS DEBUG inserting into $_tableName: $insertPayload");
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .insert(insertPayload)
          .select()
          .single();

      if (kDebugMode) print("SOS INSERT RESULT: $response");
    } catch (e) {
      if (kDebugMode) print("SOS DEBUG ERROR during insert: $e");
      rethrow;
    }
  }
}
