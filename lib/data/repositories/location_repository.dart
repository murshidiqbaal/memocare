import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_alert.dart';
import '../models/patient_live_location.dart';

class LocationRepository {
  final SupabaseClient _supabase;

  LocationRepository(this._supabase);


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
