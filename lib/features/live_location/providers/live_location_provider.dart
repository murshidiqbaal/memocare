import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../providers/service_providers.dart';
import '../../patient_selection/providers/patient_selection_provider.dart';
import '../data/patient_location_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stream Provider — auto-manages realtime subscription for selected patient
//
// Automatically:
//   • cancels and resubscribes when selected patient changes
//   • disposes channel on widget teardown (autoDispose)
//   • emits null when no patient selected
// ─────────────────────────────────────────────────────────────────────────────
final liveLocationStreamProvider =
    StreamProvider.autoDispose<PatientLocation?>((ref) {
  final selectedPatientId =
      ref.watch(patientSelectionProvider.select((s) => s.selectedPatient?.id));

  if (selectedPatientId == null || selectedPatientId.isEmpty) {
    return Stream.value(null);
  }

  final supabase = ref.watch(supabaseClientProvider);
  final service = LiveLocationService(supabase);

  // Guaranteed cleanup when provider is disposed or patient changes
  ref.onDispose(service.dispose);

  return service.subscribeToPatientLocation(selectedPatientId);
});

// ─────────────────────────────────────────────────────────────────────────────
// LiveLocationService
//
// Production-grade real-time location service:
//   • Fetches initial location immediately (no blank state)
//   • Subscribes to Supabase Realtime postgres_changes
//   • Debounces rapid updates (300ms) to prevent rebuild storms
//   • Handles channel errors / unexpected closes with auto-retry (max 3 attempts)
//   • Safe broadcast stream (multiple listeners OK)
//   • Thread-safe dispose (checks isClosed before emitting)
// ─────────────────────────────────────────────────────────────────────────────
class LiveLocationService {
  final SupabaseClient _supabase;

  RealtimeChannel? _channel;
  final StreamController<PatientLocation?> _controller =
      StreamController<PatientLocation?>.broadcast();

  // Debounce
  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 300);

  // Retry
  int _retryCount = 0;
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 3);
  Timer? _retryTimer;

  String? _activePatientId;

  LiveLocationService(this._supabase);

  /// Returns a live stream of [PatientLocation] for [patientId].
  ///
  /// 1. Immediately fetches the latest record from DB (cold-start UX)
  /// 2. Sets up Realtime subscription for live updates
  Stream<PatientLocation?> subscribeToPatientLocation(String patientId) {
    _activePatientId = patientId;
    _fetchInitialLocation(patientId);
    _subscribe(patientId);
    return _controller.stream;
  }

  // ── Initial fetch ──────────────────────────────────────────────────────────

  Future<void> _fetchInitialLocation(String patientId) async {
    try {
      final response = await _supabase
          .from('patient_locations')
          .select()
          .eq('patient_id', patientId)
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && !_controller.isClosed) {
        _emit(PatientLocation.fromJson(response));
      }
    } catch (e) {
      // Non-fatal: Realtime will push once location exists
      _debugLog('Initial fetch failed: $e');
    }
  }

  // ── Realtime subscription ──────────────────────────────────────────────────

  void _subscribe(String patientId) {
    // Tear down existing channel before creating a new one
    _teardown();

    final channelName =
        'patient_location_${patientId}_${DateTime.now().millisecondsSinceEpoch}';

    _channel = _supabase.channel(channelName);

    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'patient_locations',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'patient_id',
            value: patientId,
          ),
          callback: _handlePayload,
        )
        .subscribe(_handleSubscribeStatus);
  }

  void _handlePayload(PostgresChangePayload payload) {
    if (_controller.isClosed) return;

    if (payload.eventType == PostgresChangeEvent.delete) {
      // Location row deleted → emit null (patient went offline)
      _scheduleEmit(null);
      return;
    }

    final record = payload.newRecord;
    if (record.isEmpty) return;

    try {
      final loc = PatientLocation.fromJson(record);
      _debugLog('Realtime update → ${loc.latitude}, ${loc.longitude}');
      _scheduleEmit(loc);
    } catch (e) {
      _debugLog('Payload parse error: $e');
    }
  }

  void _handleSubscribeStatus(RealtimeSubscribeStatus status, [Object? error]) {
    _debugLog('Channel status: $status  error: $error');

    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        // Reset retry counter on successful subscribe
        _retryCount = 0;
        break;

      case RealtimeSubscribeStatus.closed:
      case RealtimeSubscribeStatus.channelError:
        // Unexpected disconnect → schedule retry
        if (!_controller.isClosed && _activePatientId != null) {
          _scheduleRetry(_activePatientId!);
        }
        break;

      case RealtimeSubscribeStatus.timedOut:
        if (!_controller.isClosed && _activePatientId != null) {
          _scheduleRetry(_activePatientId!);
        }
        break;
    }
  }

  // ── Retry logic ────────────────────────────────────────────────────────────

  void _scheduleRetry(String patientId) {
    if (_retryCount >= _maxRetries) {
      _debugLog('Max retries ($maxRetries) reached — giving up.');
      return;
    }
    _retryCount++;
    _debugLog('Retry $_retryCount/$_maxRetries in ${_retryDelay.inSeconds}s…');

    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay * _retryCount, () {
      if (!_controller.isClosed) {
        _subscribe(patientId);
      }
    });
  }

  // ── Debounce emitter ───────────────────────────────────────────────────────

  void _scheduleEmit(PatientLocation? location) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _emit(location));
  }

  void _emit(PatientLocation? location) {
    if (!_controller.isClosed) {
      _controller.add(location);
    }
  }

  // ── Teardown ───────────────────────────────────────────────────────────────

  void _teardown() {
    _channel?.unsubscribe();
    _channel = null;
    _debounce?.cancel();
    _retryTimer?.cancel();
  }

  void dispose() {
    _activePatientId = null;
    _teardown();
    if (!_controller.isClosed) {
      _controller.close();
    }
    _debugLog('Disposed.');
  }

  // ── Debug ──────────────────────────────────────────────────────────────────

  void _debugLog(String msg) {
    // ignore: avoid_print
    assert(() {
      // Only prints in debug mode
      print('[LiveLocationService] $msg');
      return true;
    }());
  }

  static int get maxRetries => _maxRetries;
}
