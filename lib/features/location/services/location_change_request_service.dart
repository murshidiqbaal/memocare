import 'package:dementia_care_app/data/repositories/safe_zone_repository.dart';
import 'package:dementia_care_app/features/location/models/location_change_request.dart';
import 'package:flutter/foundation.dart';
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
    // ─── LOGGING ──────────────────────────────────────────────────────────
    debugPrint('═══════════════════════════════════════════════');
    debugPrint('📍 SUBMITTING LOCATION REQUEST');
    debugPrint('Patient ID: $patientId');
    debugPrint('Latitude: $latitude');
    debugPrint('Longitude: $longitude');
    debugPrint('Radius: $radius meters');
    debugPrint('═══════════════════════════════════════════════');

    try {
      final response = await _supabase.functions.invoke(
        'submit-location-request',
        body: {
          'patient_id': patientId,
          'latitude': latitude,
          'longitude': longitude,
          'radius': radius,
        },
      );

      if (response.status == 200 || response.status == 201) {
        debugPrint(
            '✅ SUCCESS: Location change request submitted successfully.');
      } else {
        debugPrint('❌ ERROR: Edge Function returned status ${response.status}');
        debugPrint('Response body: ${response.data}');
        throw Exception('Edge Function failed with status ${response.status}');
      }
    } on FunctionException catch (fe) {
      debugPrint('❌ SUBMISSION FAILED (FunctionException)');
      debugPrint('Status: ${fe.status}');
      debugPrint('Details: ${fe.details}');
      rethrow;
    } catch (e) {
      debugPrint('❌ SUBMISSION FAILED (Generic Exception)');
      debugPrint('Error: $e');
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
          .eq('status', 'requested')
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
          .eq('status', 'requested')
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
  /// Updates `location_change_requests` status AND upserts the new `safe_zones` row.
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
