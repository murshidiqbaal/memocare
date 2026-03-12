import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:memocare/core/errors/failures.dart';
import 'package:memocare/data/models/sos_alert.dart';
import 'package:memocare/features/safety/data/models/live_location.dart';
import 'package:memocare/providers/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SosRepository {
  final SupabaseClient _supabase;
  static const _tableName = 'sos_alerts'; // Canonical table
  final _uuid = const Uuid();

  SosRepository(this._supabase);

  // --- Patient Trigger Methods ---

  Future<SosAlert> createSosAlert(String patientId, double lat, double long,
      {String? message}) async {
    final response = await _supabase
        .from(_tableName)
        .insert({
          'id': _uuid.v4(),
          'patient_id': patientId,
          'latitude': lat,
          'longitude': long,
          'status': 'active',
          'message': message ?? 'SOS emergency triggered',
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return SosAlert.fromJson(response);
  }

  // --- Location Updates ---

  Future<void> updateLiveLocation(
      String patientId, double lat, double long) async {
    // 1. Insert into history
    await _supabase.from('live_locations').insert({
      'patient_id': patientId,
      'latitude': lat,
      'longitude': long,
      'recorded_at': DateTime.now().toIso8601String(),
    });

    // 2. Update active alert for quick reference
    await _supabase
        .from(_tableName)
        .update({
          'latitude': lat,
          'longitude': long,
        })
        .eq('patient_id', patientId)
        .inFilter('status', ['active', 'sent', 'pending']);
  }

  // --- Caregiver & Resolution ---

  Future<void> resolveSosAlert(String alertId) async {
    await _supabase.from(_tableName).update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  Future<void> acknowledgeAlert(String alertId) async {
    await _supabase.from(_tableName).update({
      'status': 'acknowledged',
      'acknowledged_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  // --- Retrieval & Streams ---

  Future<SosAlert?> getActiveAlert(String patientId) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('patient_id', patientId)
        .inFilter('status', ['active', 'sent', 'pending']).maybeSingle();

    if (response == null) return null;
    return SosAlert.fromJson(response);
  }

  Stream<List<SosAlert>> watchActiveAlerts() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .inFilter('status', ['active', 'sent', 'pending'])
        .order('created_at', ascending: false)
        .map((data) => data.map((json) => SosAlert.fromJson(json)).toList());
  }

  Stream<List<SosAlert>> watchAlertsForCaregiver() => watchActiveAlerts();

  Stream<List<LiveLocation>> streamLiveLocation(String patientId) {
    return _supabase
        .from('live_locations')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .map(
            (data) => data.map((json) => LiveLocation.fromJson(json)).toList());
  }

  Stream<List<SosAlert>> streamActiveAlerts() => watchActiveAlerts();

  // --- Legacy Support (Compatibility for other parts of the app) ---

  Future<void> resolveAlert(String alertId) => resolveSosAlert(alertId);

  Future<void> sendSos({required double? lat, required double? lon}) =>
      triggerSOS();

  Future<SosTriggerResult> triggerSOS(
      {String message = 'SOS emergency triggered'}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return const SosTriggerResult(
            sent: 0, queued: false, error: 'User not logged in');
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));

      await createSosAlert(user.id, pos.latitude, pos.longitude,
          message: message);

      return const SosTriggerResult(sent: 1, queued: false, error: null);
    } catch (e) {
      return SosTriggerResult(sent: 0, queued: false, error: e.toString());
    }
  }

  Future<Either<Failure, SosAlert>> sendEmergencyAlert() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return const Left(AuthFailure('No user'));

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 3));

      final alert = await createSosAlert(user.id, pos.latitude, pos.longitude);
      return Right(alert);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Stream<List<SosAlert>> watchLinkedPatientsAlerts() => watchActiveAlerts();

  Future<List<SosAlert>> getLinkedPatientsActiveAlerts() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .inFilter('status', ['active', 'sent', 'pending']);
    return (response as List).map((j) => SosAlert.fromJson(j)).toList();
  }
}

class SosTriggerResult {
  final int sent;
  final bool queued;
  final String? error;

  const SosTriggerResult({
    required this.sent,
    required this.queued,
    required this.error,
  });

  bool get isSuccess => error == null;
}

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return SosRepository(supabase);
});
