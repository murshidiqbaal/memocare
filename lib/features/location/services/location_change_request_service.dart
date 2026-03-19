import 'package:flutter/foundation.dart';
import 'package:memocare/data/repositories/safe_zone_repository.dart';
import 'package:memocare/features/location/models/location_change_request.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages the patient → caregiver location change approval flow.
///
/// Patients submit a request via Edge Function; caregivers approve/reject.
class LocationChangeRequestService {
  final SupabaseClient _supabase;
  final SafeZoneRepository _safeZoneRepository;

  LocationChangeRequestService({
    required SupabaseClient supabase,
    required SafeZoneRepository safeZoneRepository,
  })  : _supabase = supabase,
        _safeZoneRepository = safeZoneRepository;

  // ─────────────────────────────────────────────────────────────────────────
  // Patient side
  // ─────────────────────────────────────────────────────────────────────────

  /// Patient submits a request to change their home location.
  ///
  /// Calls the 'submit-location-request' Supabase Edge Function.
  Future<void> submitRequest({
    required String patientId,
    required double latitude,
    required double longitude,
    required int radius,
  }) async {
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📍 SUBMITTING LOCATION REQUEST');
    debugPrint('Patient ID: $patientId');
    debugPrint('Latitude: $latitude');
    debugPrint('Longitude: $longitude');
    debugPrint('Radius: $radius meters');
    debugPrint('═══════════════════════════════════════════════');

    try {
      await _supabase.from('location_change_requests').insert({
        'patient_id': patientId,
        'requested_latitude': latitude,
        'requested_longitude': longitude,
        'requested_radius_meters': radius,
        'status': 'requested',
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint("✅ SUCCESS: Location request inserted.");
    } catch (e) {
      debugPrint("❌ SUBMISSION FAILED");
      debugPrint("Error: $e");
      rethrow;
    }
  }

  /// Gets all requests for the current patient.
  Future<List<LocationChangeRequest>> getPatientRequests(
      String patientId) async {
    try {
      final data = await _supabase
          .from('location_change_requests')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => LocationChangeRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          '[LocationChangeRequestService] Get patient requests error: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Caregiver side
  // ─────────────────────────────────────────────────────────────────────────

  /// Gets all REQUESTED (pending) requests for a specific patient.
  Future<List<LocationChangeRequest>> getPatientPendingRequests(
      String patientId) async {
    try {
      final data = await _supabase
          .from('location_change_requests')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => LocationChangeRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint(
          '[LocationChangeRequestService] Patient pending requests error: $e');
      return [];
    }
  }

  /// Gets all REQUESTED (pending) requests for all patients linked to [caregiverId].
  Future<List<LocationChangeRequest>> getPendingRequestsForCaregiver(
      String caregiverId) async {
    try {
      // Get linked patient IDs
      final links = await _supabase
          .from('caregiver_patient_links')
          .select('patient_id')
          .eq('caregiver_id', caregiverId);

      if ((links as List).isEmpty) return [];

      final patientIds = links.map((l) => l['patient_id'] as String).toList();

      final data = await _supabase
          .from('location_change_requests')
          .select()
          .inFilter('patient_id', patientIds)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => LocationChangeRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[LocationChangeRequestService] Pending requests error: $e');
      return [];
    }
  }

  /// Caregiver approves a request.
  /// Updates `location_change_requests` status AND upserts the new `patient_home_locations` row.
  Future<void> approveRequest({
    required String requestId,
    required String caregiverId,
    required LocationChangeRequest request,
    required String label,
  }) async {
    try {
      // 1. Update request status
      await _supabase.from('location_change_requests').update({
        'status': 'approved',
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      // 2. Update the actual safe zone
      await _safeZoneRepository.upsertSafeZone(
        patientId: request.patientId,
        latitude: request.requestedLatitude,
        longitude: request.requestedLongitude,
        radiusMeters: request.requestedRadiusMeters,
        label: label,
        homeLat: request.requestedLatitude,
        homeLng: request.requestedLongitude,
        radius: 500,
      );

      debugPrint(
          '[LocationChangeRequestService] Request $requestId approved by $caregiverId');
    } catch (e) {
      debugPrint('[LocationChangeRequestService] Approve error: $e');
      throw Exception('Failed to approve request: $e');
    }
  }

  /// Caregiver rejects a request.
  Future<void> rejectRequest({
    required String requestId,
    required String caregiverId,
  }) async {
    try {
      await _supabase.from('location_change_requests').update({
        'status': 'rejected',
        'reviewed_at': DateTime.now().toIso8601String(),
      }).eq('id', requestId);

      debugPrint('[LocationChangeRequestService] Request $requestId rejected.');
    } catch (e) {
      debugPrint('[LocationChangeRequestService] Reject error: $e');
      throw Exception('Failed to reject request: $e');
    }
  }
}
