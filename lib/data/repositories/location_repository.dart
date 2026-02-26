import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_alert.dart';
import '../models/patient_home_location.dart';

class LocationRepository {
  final SupabaseClient _supabase;

  LocationRepository(this._supabase);

  Future<void> upsertPatientHomeLocation(PatientHomeLocation location) async {
    await _supabase.from('patient_home_locations').upsert(
      {
        'patient_id': location.patientId,
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

  Future<void> insertLocationAlert({
    required String patientId,
    required String caregiverId,
    required double latitude,
    required double longitude,
    required double distanceMeters,
  }) async {
    await _supabase.from('location_alerts').insert({
      'patient_id': patientId,
      'caregiver_id': caregiverId,
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
