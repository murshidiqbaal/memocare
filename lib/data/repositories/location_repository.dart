import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_alert.dart';
import '../models/patient_home_location.dart';
import '../models/patient_live_location.dart';

class LocationRepository {
  final SupabaseClient _supabase;

  LocationRepository(this._supabase);

  Future<void> upsertPatientHomeLocation(PatientHomeLocation location) async {
    // Resolve internal patient ID
    final patientRow = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', location.patientId)
        .maybeSingle();
    final String resolvedId = patientRow?['id'] ?? location.patientId;

    await _supabase.from('patient_home_locations').upsert(
      {
        'patient_id': resolvedId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'radius_meters': location.radiusMeters,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'patient_id',
    );
  }

  Future<PatientHomeLocation?> getPatientHomeLocation(String patientId) async {
    final response = await _supabase
        .from('patient_home_locations')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (response == null) return null;
    return PatientHomeLocation.fromJson(response);
  }

  Future<void> updateLiveLocation({
    required String patientId,
    required double latitude,
    required double longitude,
  }) async {
    // Resolve internal patient ID
    final patientRow = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();
    final String resolvedId = patientRow?['id'] ?? patientId;

    await _supabase.from('patient_live_locations').upsert({
      'patient_id': resolvedId,
      'latitude': latitude,
      'longitude': longitude,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'patient_id');
  }

  Future<PatientLiveLocation?> getPatientLiveLocation(String patientId) async {
    final response = await _supabase
        .from('patient_live_locations')
        .select()
        .eq('patient_id', patientId)
        .maybeSingle();

    if (response == null) return null;
    return PatientLiveLocation.fromJson(response);
  }

  Stream<PatientLiveLocation?> watchPatientLiveLocation(String patientId) {
    return _supabase
        .from('patient_live_locations')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .limit(1)
        .map((data) =>
            data.isEmpty ? null : PatientLiveLocation.fromJson(data.first));
  }

  Future<void> insertLocationAlert({
    required String patientId,
    required String caregiverId,
    required double latitude,
    required double longitude,
    required double distanceMeters,
  }) async {
    // Resolve internal IDs
    final patientRow = await _supabase
        .from('patients')
        .select('id')
        .eq('user_id', patientId)
        .maybeSingle();
    final String resolvedPatientId = patientRow?['id'] ?? patientId;

    final caregiverRow = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', caregiverId)
        .maybeSingle();
    final String resolvedCaregiverId = caregiverRow?['id'] ?? caregiverId;

    print(
        'Inserting Location Alert: Patient=$resolvedPatientId, Caregiver=$resolvedCaregiverId');

    await _supabase.from('location_alerts').insert({
      'patient_id': resolvedPatientId,
      'caregiver_id': resolvedCaregiverId,
      'latitude': latitude,
      'longitude': longitude,
      'distance_meters': distanceMeters,
    });
  }

  Stream<List<LocationAlert>> streamCaregiverAlerts(String caregiverId) {
    return _supabase
        .from('location_alerts')
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => LocationAlert.fromJson(json)).toList());
  }
}
