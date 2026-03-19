// lib/data/repositories/sos_repository.dart
import 'dart:async';
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:memocare/core/errors/failures.dart';
import 'package:memocare/core/providers/supabase_provider.dart';
import 'package:memocare/data/models/sos_alert.dart';
import 'package:memocare/features/safety/data/models/live_location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/uuid_validator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  return SosRepository(ref.watch(supabaseClientProvider));
});

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class SosRepository {
  final SupabaseClient _supabase;
  static const _offlineKey = 'sos_offline_queue_v2';
  static const _tableName = 'sos_messages';
  static const _defaultMessage = 'SOS emergency triggered';

  final _uuid = const Uuid();
  bool _isSending = false;

  SosRepository(this._supabase);

  // ── TRIGGER SOS ────────────────────────────────────────────────────────────

  Future<SosTriggerResult> triggerSOS({
    String message = _defaultMessage,
  }) async {
    if (_isSending) {
      return const SosTriggerResult(sent: 0, queued: true, error: null);
    }
    _isSending = true;

    String patientId = '';
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) {
        return const SosTriggerResult(
            sent: 0, queued: false, error: 'Not authenticated');
      }

      // Resolve internal patient ID (patients.id)
      final patientRow = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', authId)
          .maybeSingle();

      if (patientRow == null) {
        return const SosTriggerResult(
            sent: 0, queued: false, error: 'Patient profile not found');
      }
      patientId = patientRow['id'] as String;

      final (lat, lng) = await _safeLocation();
      final caregiverIds = await _fetchLinkedCaregiverIds(patientId);
      final now = DateTime.now().toIso8601String();

      print(
          'Triggering SOS for Internal Patient ID: $patientId (Auth: $authId)');

      // Validate patient and caregiver UUIDs
      if (!isValidUuid(patientId)) {
        throw Exception('Invalid patient ID');
      }

      final validCaregivers = caregiverIds.where(isValidUuid).toList();
      if (validCaregivers.isEmpty) {
        throw Exception('Invalid caregiver ID');
      }

      final payloads = _buildPayloads(
        patientId: patientId,
        caregiverIds: validCaregivers,
        lat: lat,
        lng: lng,
        message: message,
        now: now,
      );

      await _supabase.from(_tableName).insert(payloads);

      unawaited(_drainOfflineQueue());
      return SosTriggerResult(
          sent: payloads.length, queued: false, error: null);
    } catch (e) {
      if (kDebugMode) print('[SosRepo] triggerSOS Error: $e');
      await _enqueueOffline(
        patientId:
            patientId, // Already resolved if we reached here, or handle elsewhere
        message: message,
      );
      return SosTriggerResult(sent: 0, queued: true, error: e.toString());
    } finally {
      _isSending = false;
    }
  }

  // Compatibility method
  Future<SosAlert> createSosAlert(String patientId, double lat, double long,
      {String? message}) async {
    // Validate UUIDs
    if (!isValidUuid(patientId)) {
      throw Exception('Invalid patient ID');
    }

    final response = await _supabase
        .from(_tableName)
        .insert({
          'id': _uuid.v4(),
          'patient_id': patientId,
          // createSosAlert doesn't seem to pass a caregiver_id in legacy, but
          // to suppress the error we'd ideally fetch it. However, if it's omitted
          // to rely on triggerSOS instead, let's just make sure it doesn't fail
          // if there is a caregiver column. If it's omitted, Supabase handles it.
          'location_lat': lat,
          'location_lng': long,
          'status': 'active',
          'message': message ?? _defaultMessage,
          'triggered_at': DateTime.now().toIso8601String(),
        })
        .select()
        .maybeSingle();

    return SosAlert.fromJson(response!);
  }

  Future<Either<Failure, SosAlert>> sendEmergencyAlert() async {
    try {
      final authId = _supabase.auth.currentUser?.id;
      if (authId == null) return const Left(AuthFailure('No user'));

      // Resolve internal patient ID
      final patientRow = await _supabase
          .from('patients')
          .select('id')
          .eq('user_id', authId)
          .maybeSingle();

      if (patientRow == null)
        return const Left(ServerFailure('Patient profile missing'));
      final String patientId = patientRow['id'];

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 3));

      final alert =
          await createSosAlert(patientId, pos.latitude, pos.longitude);
      return Right(alert);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── LOCATION UPDATES ───────────────────────────────────────────────────────

  Future<void> updateLiveLocation(
      String patientId, double lat, double long) async {
    await _supabase.from('live_locations').insert({
      'patient_id': patientId,
      'latitude': lat,
      'longitude': long,
      'recorded_at': DateTime.now().toIso8601String(),
    });

    await _supabase
        .from(_tableName)
        .update({'location_lat': lat, 'location_lng': long})
        .eq('patient_id', patientId)
        .inFilter('status', ['active', 'sent', 'pending']);
  }

  // ── ACKNOWLEDGE / RESOLVE ──────────────────────────────────────────────────

  Future<void> acknowledgeAlert(String alertId) async {
    await _supabase.from(_tableName).update({
      'status': 'acknowledged',
      'acknowledged_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  Future<void> resolveAlert(String alertId) async {
    await _supabase.from(_tableName).update({
      'status': 'resolved',
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  Future<void> resolveSosAlert(String alertId) => resolveAlert(alertId);

  // ── STREAMS ────────────────────────────────────────────────────────────────

  Stream<List<SosAlert>> watchAlertsForCaregiver() async* {
    final authId = _supabase.auth.currentUser?.id;
    if (authId == null) {
      yield [];
      return;
    }

    // Resolve internal caregiver ID
    final caregiverRow = await _supabase
        .from('caregiver_profiles')
        .select('id')
        .eq('user_id', authId)
        .maybeSingle();

    if (caregiverRow == null) {
      yield [];
      return;
    }
    final String caregiverId = caregiverRow['id'];

    yield await fetchActiveAlertsForCaregiver(caregiverId);

    final stream = _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .order('triggered_at', ascending: false);

    await for (final rows in stream) {
      yield rows
          .where((r) => r['status'] == 'pending' || r['status'] == 'active')
          .map((r) => SosAlert.fromJson(_normaliseRow(r)))
          .toList();
    }
  }

  Future<List<SosAlert>> fetchActiveAlertsForCaregiver(
      String caregiverId) async {
    final rows = await _supabase
        .from(_tableName)
        .select()
        .eq('caregiver_id', caregiverId)
        .inFilter('status', ['pending', 'active']).order('triggered_at',
            ascending: false);

    return (rows as List)
        .map((r) => SosAlert.fromJson(_normaliseRow(r)))
        .toList();
  }

  Stream<List<SosAlert>> streamActiveAlerts() {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .inFilter('status', ['active', 'sent', 'pending'])
        .order('triggered_at', ascending: false)
        .map((data) => data.map((json) => SosAlert.fromJson(json)).toList());
  }

  Stream<List<SosAlert>> watchActiveAlerts() => streamActiveAlerts();
  Stream<List<SosAlert>> watchLinkedPatientsAlerts() => streamActiveAlerts();

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

  Future<SosAlert?> getActiveAlert(String patientId) async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .eq('patient_id', patientId)
        .inFilter('status', ['active', 'sent', 'pending']).maybeSingle();

    if (response == null) return null;
    return SosAlert.fromJson(response);
  }

  Future<List<SosAlert>> getLinkedPatientsActiveAlerts() async {
    final response = await _supabase
        .from(_tableName)
        .select()
        .inFilter('status', ['active', 'sent', 'pending']);
    return (response as List).map((j) => SosAlert.fromJson(j)).toList();
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  Future<(double?, double?)> _safeLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) return (null, null);
      final pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high)
          .timeout(const Duration(seconds: 5));
      return (pos.latitude, pos.longitude);
    } catch (_) {
      return (null, null);
    }
  }

  Future<List<String>> _fetchLinkedCaregiverIds(String patientId) async {
    try {
      final links = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', patientId);
      return (links as List).map((l) => l['caregiver_id'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  List<Map<String, dynamic>> _buildPayloads({
    required String patientId,
    required List<String> caregiverIds,
    required double? lat,
    required double? lng,
    required String message,
    required String now,
  }) {
    if (caregiverIds.isEmpty) {
      return []; // Return empty instead of invalid caregiverId insert
    }
    return caregiverIds
        .map((cId) => {
              'id': _uuid.v4(),
              'patient_id': patientId,
              'caregiver_id': cId,
              'message': message,
              'status': 'active',
              'location_lat': lat,
              'location_lng': lng,
              'triggered_at': now,
            })
        .toList();
  }

  Future<void> _enqueueOffline(
      {required String patientId, required String message}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_offlineKey) ?? [];
      queue.add(jsonEncode({
        'patient_id': patientId,
        'message': message,
        'queued_at': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList(_offlineKey, queue);
    } catch (_) {}
  }

  Future<void> _drainOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_offlineKey);
      if (queue == null || queue.isEmpty) return;

      final remaining = <String>[];
      for (final encoded in queue) {
        try {
          final item = jsonDecode(encoded) as Map<String, dynamic>;
          final patientId = item['patient_id'] as String? ?? '';
          final message = item['message'] as String? ?? _defaultMessage;
          if (patientId.isEmpty) continue;

          final caregiverIds = await _fetchLinkedCaregiverIds(patientId);
          final now = DateTime.now().toIso8601String();

          if (!isValidUuid(patientId)) continue;
          final validCaregivers = caregiverIds.where(isValidUuid).toList();
          if (validCaregivers.isEmpty) continue;

          final payloads = _buildPayloads(
            patientId: patientId,
            caregiverIds: validCaregivers,
            lat: null,
            lng: null,
            message: message,
            now: now,
          );
          if (payloads.isNotEmpty) {
            await _supabase.from(_tableName).insert(payloads);
          }
        } catch (_) {
          remaining.add(encoded);
        }
      }

      if (remaining.isEmpty) {
        await prefs.remove(_offlineKey);
      } else {
        await prefs.setStringList(_offlineKey, remaining);
      }
    } catch (_) {}
  }

  Map<String, dynamic> _normaliseRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['triggered_at'] ??=
        row['created_at'] ?? DateTime.now().toIso8601String();
    map['latitude'] ??= row['location_lat'];
    map['longitude'] ??= row['location_lng'];
    return map;
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
