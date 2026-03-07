// lib/data/repositories/sos_repository.dart
//
// ─── SOS Repository ──────────────────────────────────────────────────────────
//
// Single source of truth for all `sos_alerts` table operations.
//
// TABLE SCHEMA (sos_alerts):
//   id              uuid  PK
//   patient_id      uuid  FK → auth.users
//   caregiver_id    uuid  FK → auth.users  (nullable — system-wide alert)
//   message         text  DEFAULT 'SOS emergency triggered'
//   status          text  DEFAULT 'active'  [active | acknowledged | resolved]
//   location_lat    float8
//   location_lng    float8
//   triggered_at    timestamptz  DEFAULT now()
//   acknowledged_at timestamptz  NULLABLE
//   note            text  NULLABLE
//
// RLS (apply in Supabase console or migration):
//   • Patients  → INSERT  WHERE patient_id  = auth.uid()
//   • Caregivers→ SELECT  WHERE caregiver_id = auth.uid()
//   • Caregivers→ UPDATE  WHERE caregiver_id = auth.uid()  (for acknowledge)
//   • Admin     → ALL
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:convert';

import 'package:dementia_care_app/core/providers/supabase_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/sos_alert.dart';

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

  /// In-flight lock to prevent duplicate simultaneous sends.
  bool _isSending = false;

  SosRepository(this._supabase);

  // ── TRIGGER SOS ────────────────────────────────────────────────────────────

  /// Core method called when the patient confirms SOS.
  ///
  /// Returns the number of alert rows inserted (0 if offline-queued).
  Future<SosTriggerResult> triggerSOS({
    String message = _defaultMessage,
  }) async {
    if (_isSending) {
      if (kDebugMode) print('[SosRepo] duplicate send blocked');
      return const SosTriggerResult(sent: 0, queued: true, error: null);
    }
    _isSending = true;

    try {
      final patientId = _supabase.auth.currentUser?.id;
      if (patientId == null) {
        return const SosTriggerResult(
            sent: 0, queued: false, error: 'Not authenticated');
      }

      // 1. Try to get GPS location (non-blocking, 5s timeout)
      final (lat, lng) = await _safeLocation();

      // 2. Fetch linked caregivers
      final caregiverIds = await _fetchLinkedCaregiverIds(patientId);

      // 3. Build payloads
      final now = DateTime.now().toIso8601String();
      final payloads = _buildPayloads(
        patientId: patientId,
        caregiverIds: caregiverIds,
        lat: lat,
        lng: lng,
        message: message,
        now: now,
      );

      // 4. Insert into Supabase
      await _supabase.from(_tableName).insert(payloads);

      if (kDebugMode) {
        print('[SosRepo] ✅ Inserted ${payloads.length} SOS row(s)');
      }

      // 5. Trigger edge functions (best-effort, never block SOS)
      await _callEdgeFunctions(patientId: patientId, lat: lat, lng: lng);

      // 6. Drain offline queue if any built up
      unawaited(_drainOfflineQueue());

      return SosTriggerResult(
          sent: payloads.length, queued: false, error: null);
    } catch (e, st) {
      if (kDebugMode) {
        print('[SosRepo] ❌ triggerSOS failed: $e');
        print(st);
      }
      // Fallback: queue offline so it syncs later
      await _enqueueOffline(
        patientId: _supabase.auth.currentUser?.id ?? '',
        message: message,
      );
      return SosTriggerResult(sent: 0, queued: true, error: e.toString());
    } finally {
      _isSending = false;
    }
  }

  // ── ACKNOWLEDGE ────────────────────────────────────────────────────────────

  /// Caregiver acknowledges an alert. Updates status + acknowledged_at.
  Future<void> acknowledgeAlert(String alertId) async {
    await _supabase.from(_tableName).update({
      'status': 'acknowledged',
      'acknowledged_at': DateTime.now().toIso8601String(),
    }).eq('id', alertId);
  }

  // ── RESOLVE ────────────────────────────────────────────────────────────────

  /// Mark alert resolved (caregiver action).
  Future<void> resolveAlert(String alertId) async {
    await _supabase.from(_tableName).update({
      'status': 'resolved',
    }).eq('id', alertId);
  }

  // ── STREAM (caregiver realtime) ────────────────────────────────────────────

  /// Returns a stream of active SOS alerts filtered to the current caregiver.
  /// Uses Supabase `.stream()` which re-emits on any row change automatically.
  Stream<List<SosAlert>> watchAlertsForCaregiver() async* {
    final caregiverId = _supabase.auth.currentUser?.id;
    if (caregiverId == null) {
      yield [];
      return;
    }
    // Initial emit of current data
    yield await fetchActiveAlertsForCaregiver(caregiverId);

    // Real-time stream — filtered to this caregiver
    final stream = _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .eq('caregiver_id', caregiverId)
        .order('created_at', ascending: false);

    await for (final rows in stream) {
      yield rows
          .where((r) => r['status'] == 'pending')
          .map((r) => SosAlert.fromJson(_normaliseRow(r)))
          .toList();
    }
  }

  /// One-shot fetch of active alerts for a caregiver (also used in initial seed).
  Future<List<SosAlert>> fetchActiveAlertsForCaregiver(
      String caregiverId) async {
    try {
      final rows = await _supabase
          .from(_tableName)
          .select()
          .eq('caregiver_id', caregiverId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (rows as List)
          .map((r) => SosAlert.fromJson(_normaliseRow(r)))
          .toList();
    } catch (e) {
      if (kDebugMode) print('[SosRepo] fetchActive error: $e');
      return [];
    }
  }

  /// Fetch ALL alerts for a patient (history view).
  Future<List<SosAlert>> fetchHistoryForPatient(String patientId,
      {int limit = 20}) async {
    try {
      final rows = await _supabase
          .from(_tableName)
          .select()
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (rows as List)
          .map((r) => SosAlert.fromJson(_normaliseRow(r)))
          .toList();
    } catch (e) {
      if (kDebugMode) print('[SosRepo] fetchHistory error: $e');
      return [];
    }
  }

  // ── PRIVATE HELPERS ────────────────────────────────────────────────────────

  /// Safe GPS fetch — never throws. Returns (null, null) on any failure.
  Future<(double?, double?)> _safeLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return (null, null);
      }
      final pos = await Geolocator.getCurrentPosition(
        // ignore: deprecated_member_use
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));
      return (pos.latitude, pos.longitude);
    } catch (_) {
      return (null, null);
    }
  }

  /// Fetch all caregiver user IDs linked to a patient.
  Future<List<String>> _fetchLinkedCaregiverIds(String patientId) async {
    try {
      final links = await _supabase
          .from('caregiver_patient_links')
          .select('caregiver_id')
          .eq('patient_id', patientId);

      return (links as List).map((l) => l['caregiver_id'] as String).toList();
    } catch (e) {
      if (kDebugMode) print('[SosRepo] _fetchLinkedCaregiverIds error: $e');
      return [];
    }
  }

  /// Build one payload row per linked caregiver (or a system row if none).
  List<Map<String, dynamic>> _buildPayloads({
    required String patientId,
    required List<String> caregiverIds,
    required double? lat,
    required double? lng,
    required String message,
    required String now,
  }) {
    if (caregiverIds.isEmpty) {
      return [
        {
          'id': _uuid.v4(),
          'patient_id': patientId,
          'caregiver_id': null,
          'message': message,
          'status': 'pending',
          'location_lat': lat,
          'location_lng': lng,
          'created_at': now,
        }
      ];
    }
    return caregiverIds
        .map((cId) => {
              'id': _uuid.v4(),
              'patient_id': patientId,
              'caregiver_id': cId,
              'message': message,
              'status': 'pending',
              'location_lat': lat,
              'location_lng': lng,
              'created_at': now,
            })
        .toList();
  }

  /// Invoke Supabase Edge Functions for email and SMS (best-effort).
  Future<void> _callEdgeFunctions({
    required String patientId,
    required double? lat,
    required double? lng,
  }) async {
    final body = {
      'patient_id': patientId,
      if (lat != null) 'latitude': lat,
      if (lng != null) 'longitude': lng,
    };

    // Email notification
    try {
      await _supabase.functions
          .invoke('send-sos-email', body: body)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      if (kDebugMode) print('[SosRepo] send-sos-email failed (non-fatal): $e');
    }

    // SMS notification (placeholder — wired to edge function)
    try {
      await _supabase.functions
          .invoke('send-sos-sms', body: body)
          .timeout(const Duration(seconds: 8));
    } catch (e) {
      if (kDebugMode) print('[SosRepo] send-sos-sms failed (non-fatal): $e');
    }
  }

  // ── OFFLINE QUEUE ──────────────────────────────────────────────────────────

  Future<void> _enqueueOffline({
    required String patientId,
    required String message,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = prefs.getStringList(_offlineKey) ?? [];
      queue.add(jsonEncode({
        'patient_id': patientId,
        'message': message,
        'queued_at': DateTime.now().toIso8601String(),
      }));
      await prefs.setStringList(_offlineKey, queue);
      if (kDebugMode) print('[SosRepo] Queued offline SOS.');
    } catch (e) {
      if (kDebugMode) print('[SosRepo] _enqueueOffline failed: $e');
    }
  }

  /// Re-sends locally queued SOS records when connectivity restores.
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
          final payloads = _buildPayloads(
            patientId: patientId,
            caregiverIds: caregiverIds,
            lat: null,
            lng: null,
            message: message,
            now: now,
          );
          await _supabase.from(_tableName).insert(payloads);
          if (kDebugMode) print('[SosRepo] Drained 1 offline SOS');
        } catch (e) {
          remaining.add(encoded); // keep for next attempt
        }
      }

      if (remaining.isEmpty) {
        await prefs.remove(_offlineKey);
      } else {
        await prefs.setStringList(_offlineKey, remaining);
      }
    } catch (e) {
      if (kDebugMode) print('[SosRepo] _drainOfflineQueue error: $e');
    }
  }

  /// Normalise Supabase row → `created_at` is canonical.
  Map<String, dynamic> _normaliseRow(Map<String, dynamic> row) {
    final map = Map<String, dynamic>.from(row);
    map['created_at'] ??=
        row['triggered_at'] ?? DateTime.now().toIso8601String();
    return map;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Result type
// ─────────────────────────────────────────────────────────────────────────────

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
