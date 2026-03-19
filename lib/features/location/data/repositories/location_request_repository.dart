import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/location_request.dart';

class LocationRequestRepository {
  final SupabaseClient _supabase;

  LocationRequestRepository(this._supabase);

  /// Patient requests a location change
  Future<void> requestLocationChange({
    required String patientId,
    required String caregiverId,
    required double lat,
    required double lng,
    required int radius,
  }) async {
    await _supabase.from('location_change_requests').insert({
      'patient_id': patientId,
      'caregiver_id': caregiverId,
      'requested_latitude': lat,
      'requested_longitude': lng,
      'requested_radius_meters': radius,
      'status': 'pending',
    });
  }

  /// Caregiver fetches pending requests
  Future<List<LocationRequest>> getPendingRequests(String caregiverId) async {
    final data = await _supabase
        .from('location_change_requests')
        .select()
        .eq('caregiver_id', caregiverId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);

    return (data as List)
        .map((e) => LocationRequest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Caregiver approves request
  Future<void> approveLocationRequest(LocationRequest request) async {
    final now = DateTime.now().toIso8601String();

    // 1. Update request status
    await _supabase.from('location_change_requests').update({
      'status': 'approved',
      'reviewed_at': now,
    }).eq('id', request.id);

    // 2. Update patient_patient_home_locations
    await _supabase.from('patient_patient_home_locations').upsert({
      'patient_id': request.patientId,
      'latitude': request.requestedLatitude,
      'longitude': request.requestedLongitude,
      'radius_meters': request.requestedRadiusMeters,
      'updated_at': now,
    }, onConflict: 'patient_id');
  }

  /// Caregiver rejects request
  Future<void> rejectLocationRequest(String requestId) async {
    await _supabase.from('location_change_requests').update({
      'status': 'rejected',
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', requestId);
  }
}
