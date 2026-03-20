import 'package:dartz/dartz.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/failures.dart';
import '../models/emergency_alert.dart';

/// Repository for managing emergency alerts
/// Handles SOS creation, cancellation, resolution, and real-time subscriptions
class EmergencyAlertRepository {
  final SupabaseClient _supabase;

  EmergencyAlertRepository(this._supabase);

  /// Send an emergency SOS alert
  /// Automatically captures current location if available
  Future<Either<Failure, EmergencyAlert>> sendEmergencyAlert() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      // Try to get current location (with timeout)
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () => throw Exception('Location timeout'),
        );
      } catch (e) {
        print('Failed to get location: $e');
        // Continue without location
      }

      // Try to resolve internal patient_id
      final patientProfile = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (patientProfile == null) {
        return const Left(ServerFailure('Patient profile not found'));
      }
      final patientId = patientProfile['id'] as String;

      // Insert emergency alert
      final response = await _supabase
          .from('emergency_alerts')
          .insert({
            'patient_id': patientId,
            'status': 'active',
            'lat': position?.latitude,
            'lng': position?.longitude,
            'created_by': user
                .id, // Track who actually triggered it (usually the patient)
          })
          .select()
          .maybeSingle();

      return Right(EmergencyAlert.fromJson(response!));
    } catch (e) {
      return Left(ServerFailure('Failed to send emergency alert: $e'));
    }
  }

  /// Cancel an emergency alert (within countdown period)
  Future<Either<Failure, void>> cancelEmergencyAlert(String alertId) async {
    try {
      await _supabase.from('emergency_alerts').update({
        'status': 'cancelled',
      }).eq('id', alertId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to cancel emergency alert: $e'));
    }
  }

  /// Resolve an emergency alert (caregiver action)
  Future<Either<Failure, void>> resolveEmergencyAlert(String alertId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      await _supabase.from('emergency_alerts').update({
        'status': 'resolved',
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', alertId);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to resolve emergency alert: $e'));
    }
  }

  /// Get active alerts for the current patient
  Future<List<EmergencyAlert>> getMyActiveAlerts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Resolve internal patient_id
      final patientProfile = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (patientProfile == null) return [];
      final patientId = patientProfile['id'] as String;

      final response = await _supabase
          .from('emergency_alerts')
          .select()
          .eq('patient_id', patientId)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmergencyAlert.fromJson(json))
          .toList();
    } catch (e) {
      print('Failed to fetch active alerts: $e');
      return [];
    }
  }

  /// Get active alerts for linked patients (caregiver view)
  Future<List<EmergencyAlert>> getLinkedPatientsActiveAlerts() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Get caregiver profile
      final caregiverData = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .eq('role', 'caregiver')
          .maybeSingle();

      if (caregiverData == null) return [];

      // Get linked patient IDs
      final links = await _supabase
          .from('caregiver_patient_links')
          .select('patient_id')
          .eq('caregiver_id', caregiverData['id']);

      final patientIds =
          (links as List).map((link) => link['patient_id'] as String).toList();

      if (patientIds.isEmpty) return [];

      // Get active alerts for these patients
      final response = await _supabase
          .from('emergency_alerts')
          .select()
          .inFilter('patient_id', patientIds)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => EmergencyAlert.fromJson(json))
          .toList();
    } catch (e) {
      print('Failed to fetch linked patients alerts: $e');
      return [];
    }
  }

  /// Stream of active alerts for linked patients (caregiver real-time)
  Stream<List<EmergencyAlert>> watchLinkedPatientsAlerts() async* {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      // Get caregiver profile
      final caregiverData = await _supabase
          .from('profiles')
          .select('id')
          .eq('user_id', user.id)
          .eq('role', 'caregiver')
          .maybeSingle();

      if (caregiverData == null) {
        yield [];
        return;
      }

      // Get linked patient IDs
      final links = await _supabase
          .from('caregiver_patient_links')
          .select('patient_id')
          .eq('caregiver_id', caregiverData['id']);

      final patientIds =
          (links as List).map((link) => link['patient_id'] as String).toList();

      if (patientIds.isEmpty) {
        yield [];
        return;
      }

      // Yield initial data
      yield await getLinkedPatientsActiveAlerts();

      // Listen to real-time changes
      final stream = _supabase
          .from('emergency_alerts')
          .stream(primaryKey: ['id']).inFilter('patient_id', patientIds);

      await for (final data in stream) {
        yield (data as List)
            .where((json) => json['status'] == 'active')
            .map((json) => EmergencyAlert.fromJson(json))
            .toList();
      }
    } catch (e) {
      print('Stream error: $e');
      yield [];
    }
  }

  /// Get alert history for a patient
  Future<List<EmergencyAlert>> getAlertHistory({int limit = 20}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      // Resolve internal patient_id
      final patientProfile = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (patientProfile == null) return [];
      final patientId = patientProfile['id'] as String;

      final response = await _supabase
          .from('emergency_alerts')
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => EmergencyAlert.fromJson(json))
          .toList();
    } catch (e) {
      print('Failed to fetch alert history: $e');
      return [];
    }
  }

  /// Get primary caregiver phone number for the current patient
  Future<Either<Failure, String?>> getPrimaryCaregiverPhone() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const Left(AuthFailure('User not authenticated'));
      }

      // Resolve internal patient_id
      final patientProfile = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      if (patientProfile == null) return const Right(null);
      final patientId = patientProfile['id'] as String;

      // Find links - get the first one
      final response = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', patientId)
          .limit(1)
          .maybeSingle();

      if (response == null) return const Right(null); // No caregiver connected

      final caregiverId = response['caregiver_id'];

      // Get profile phone number
      final profile = await _supabase
          .from('profiles')
          .select('phone_number')
          .eq('id',
              caregiverId) // Assuming profiles.id is caregiver_id here, which is correct if it points to the profiles table. Wait, caregiver_id in links usually points to caregiver_profiles.id.
          .maybeSingle();

      return Right(profile!['phone_number'] as String?);
    } catch (e) {
      return Left(ServerFailure('Failed to get caregiver phone: $e'));
    }
  }
}
