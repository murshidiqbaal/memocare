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
    print('--- RESOLVING PATIENT ID ---');
    print('[SOS Repository] auth_uid: ${user.id}');
    
    final patientResponse = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', user.id)
        .maybeSingle();

    if (patientResponse == null) {
      print('[SOS Repository] ❌ ERROR: Patient profile not found for user ${user.id}');
      throw Exception('Patient profile not found');
    }

    final patientId = patientResponse['id'] as String;
    print('[SOS Repository] ✅ Resolved patient_id: $patientId');

    // --- STEP 2: Capture location safely ---
    double? lat;
    double? lng;
    try {
      print('[SOS Repository] 📍 Capturing location...');
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 4));
        
        lat = position.latitude;
        lng = position.longitude;
        print('[SOS Repository] ✅ Location captured: $lat, $lng');
      } else {
        print('[SOS Repository] ⚠️ Location permission denied.');
      }
    } catch (e) {
       print('[SOS Repository] ⚠️ Location lookup failed/timed out: $e');
    }

    // --- STEP 3: Fetch ALL linked caregivers ---
    print('[SOS Repository] 👥 Fetching linked caregivers for patient: $patientId');
    
    final linksResponse = await _supabase
        .from('caregiver_patient_links')
        .select('caregiver_id')
        .eq('patient_id', patientId);

    final List<String?> caregiverIds = (linksResponse as List)
        .map((l) => l['caregiver_id'] as String?)
        .toList();

    if (caregiverIds.isEmpty) {
      print('[SOS Repository] ⚠️ No linked caregivers found. Sending global alert (caregiver_id: null).');
      caregiverIds.add(null);
    } else {
      print('[SOS Repository] ✅ Found ${caregiverIds.length} linked caregiver(s).');
    }

    // --- STEP 4: Insert payloads for each caregiver ---
    final now = DateTime.now().toUtc().toIso8601String();
    final List<Map<String, dynamic>> payloads = caregiverIds.map((cId) => {
      'patient_id': patientId,
      'caregiver_id': cId,
      'lat': lat,
      'lng': lng,
      'triggered_at': now,
      'status': 'active',
      'note': note ?? 'Manual Emergency SOS Alert',
    }).toList();

    try {
      print('[SOS Repository] 📤 Inserting SOS payloads into $_tableName...');
      print('[SOS Repository] Payload sample: ${payloads.first}');
      
      final response = await _supabase.from(_tableName).insert(payloads).select();
      
      print('[SOS Repository] 🚀 SOS ALERT SENT SUCCESSFULLY. Inserted rows: ${response.length}');
    } catch (e) {
      print('[SOS Repository] ❌ ERROR during database insert: $e');
      if (e is PostgrestException) {
        print('[SOS Repository] Postgrest Error Details: ${e.message} (Code: ${e.code})');
        print('[SOS Repository] Hint: ${e.hint}');
      }
      rethrow;
    }
  }
}
