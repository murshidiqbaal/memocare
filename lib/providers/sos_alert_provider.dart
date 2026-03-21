import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────
//  Model
//  Table: sos_messages
//  Columns: id | patient_id | caregiver_id | note | status
//           | is_read | triggered_at | lat | lng
// ─────────────────────────────────────────────────────────────
class SosAlert {
  final String id;
  final String patientId;
  final String? caregiverId;
  final String note;
  final String status; // 'pending' | 'acknowledged' | 'resolved'
  final bool isRead;
  final DateTime triggeredAt;
  final double? lat;
  final double? lng;

  const SosAlert({
    required this.id,
    required this.patientId,
    this.caregiverId,
    required this.note,
    required this.status,
    required this.isRead,
    required this.triggeredAt,
    this.lat,
    this.lng,
  });

  factory SosAlert.fromRow(Map<String, dynamic> r) => SosAlert(
        id: r['id']?.toString() ?? '',
        patientId: r['patient_id']?.toString() ?? '',
        caregiverId: r['caregiver_id']?.toString(),
        note: r['note']?.toString().trim().isNotEmpty == true
            ? r['note'] as String
            : 'Emergency alert triggered',
        status: r['status']?.toString() ?? 'pending',
        isRead: r['is_read'] == true,
        triggeredAt: r['triggered_at'] != null
            ? (DateTime.tryParse(r['triggered_at'].toString())?.toLocal() ??
                DateTime.now())
            : DateTime.now(),
        lat: (r['lat'] as num?)?.toDouble(),
        lng: (r['lng'] as num?)?.toDouble(),
      );

  SosAlert copyWith({bool? isRead, String? status}) => SosAlert(
        id: id,
        patientId: patientId,
        caregiverId: caregiverId,
        note: note,
        status: status ?? this.status,
        isRead: isRead ?? this.isRead,
        triggeredAt: triggeredAt,
        lat: lat,
        lng: lng,
      );

  /// True when the alert still needs caregiver action
  bool get isPending => !isRead || status == 'pending';

  /// True when GPS coordinates are attached
  bool get hasLocation => lat != null && lng != null;
}

// ─────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────
class SosAlertState {
  final List<SosAlert> alerts;
  final bool isLoading;
  final String? error;

  const SosAlertState({
    this.alerts = const [],
    this.isLoading = true,
    this.error,
  });

  SosAlertState copyWith({
    List<SosAlert>? alerts,
    bool? isLoading,
    String? error,
  }) =>
      SosAlertState(
        alerts: alerts ?? this.alerts,
        isLoading: isLoading ?? this.isLoading,
        error: error, // null clears the error
      );

  // ── Derived ─────────────────────────────────────────────────

  /// All alerts that still need caregiver action, newest first
  List<SosAlert> get unread => alerts.where((a) => a.isPending).toList()
    ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));

  /// Count of unread / pending alerts
  int get unreadCount => unread.length;

  /// The single most-recent unread alert (shown in the top banner)
  SosAlert? get latestUnread => unread.isEmpty ? null : unread.first;

  /// All acknowledged / resolved alerts, newest first
  List<SosAlert> get acknowledged => alerts.where((a) => !a.isPending).toList()
    ..sort((a, b) => b.triggeredAt.compareTo(a.triggeredAt));
}

// ─────────────────────────────────────────────────────────────
//  Notifier — family keyed on patientId (String)
// ─────────────────────────────────────────────────────────────
class SosAlertNotifier extends FamilyNotifier<SosAlertState, String> {
  StreamSubscription? _sub;

  @override
  SosAlertState build(String patientId) {
    if (patientId.isEmpty) {
      return const SosAlertState(isLoading: false);
    }
    // Kick off async init; return loading state immediately so the UI
    // can show a skeleton without blocking the first frame.
    Future.microtask(() => _init(patientId));
    ref.onDispose(_cleanup);
    return const SosAlertState();
  }

  // ── Private ─────────────────────────────────────────────────

  Future<void> _init(String patientId) async {
    await _cleanup(); // cancel any previous realtime subscription

    try {
      // Initial fetch — all alerts for this patient, newest first
      final rows = await Supabase.instance.client
          .from('sos_messages')
          .select(
              'id, patient_id, caregiver_id, note, status, is_read, triggered_at, lat, lng')
          .eq('patient_id', patientId)
          .order('triggered_at', ascending: false)
          .limit(50);

      if (kDebugMode) {
        debugPrint(
            '[SOS] fetched ${(rows as List).length} rows for $patientId');
        if ((rows).isNotEmpty) {
          debugPrint('[SOS] first row: ${(rows).first}');
        }
      }
      bool _isMounted = true;
      ref.onDispose(() => _isMounted = false);

      final alerts = _parse(rows as List);
      if (!_isMounted) return;
      state = state.copyWith(alerts: alerts, isLoading: false);

      // Realtime subscription — filtered to this patient only
      _sub = Supabase.instance.client
          .from('sos_messages')
          .stream(primaryKey: ['id'])
          .eq('patient_id', patientId)
          .order('triggered_at', ascending: false)
          .listen(
            (data) {
              if (!_isMounted) return;
              state = state.copyWith(
                alerts: _parse(data as List),
                isLoading: false,
              );
            },
            onError: (Object e) {
              if (kDebugMode) debugPrint('[SOS] stream error: $e');
              if (_isMounted)
                state = state.copyWith(isLoading: false, error: '$e');
            },
          );
    } catch (e, st) {
      if (kDebugMode) debugPrint('[SOS] fetch error: $e\n$st');
      // if (!_isMounted) {
      //   state = state.copyWith(isLoading: false, error: e.toString());
      // }
    }
  }

  List<SosAlert> _parse(List rows) => rows
      .map((r) => SosAlert.fromRow(r as Map<String, dynamic>))
      .where((a) => a.id.isNotEmpty)
      .toList();

  Future<void> _cleanup() async {
    await _sub?.cancel();
    _sub = null;
  }

  // ── Public actions ───────────────────────────────────────────

  /// Acknowledge a single SOS — updates both is_read and status
  Future<void> acknowledge(String alertId) async {
    // Optimistic update so the UI reacts immediately
    state = state.copyWith(
      alerts: state.alerts
          .map((a) => a.id == alertId
              ? a.copyWith(isRead: true, status: 'acknowledged')
              : a)
          .toList(),
    );
    try {
      await Supabase.instance.client.from('sos_messages').update({
        'is_read': true,
        'status': 'acknowledged',
      }).eq('id', alertId);
    } catch (e) {
      if (kDebugMode) debugPrint('[SOS] acknowledge error: $e');
      // The realtime stream will re-sync the true DB state automatically
    }
  }

  /// Acknowledge every pending alert for the current patient at once
  Future<void> acknowledgeAll() async {
    final patientId = arg; // FamilyNotifier exposes the arg via `arg`
    if (patientId.isEmpty) return;

    // Optimistic update
    state = state.copyWith(
      alerts: state.alerts
          .map((a) => a.copyWith(isRead: true, status: 'acknowledged'))
          .toList(),
    );
    try {
      await Supabase.instance.client
          .from('sos_messages')
          .update({
            'is_read': true,
            'status': 'acknowledged',
          })
          .eq('patient_id', patientId)
          .eq('is_read', false);
    } catch (e) {
      if (kDebugMode) debugPrint('[SOS] acknowledgeAll error: $e');
    }
  }

  /// Mark as fully resolved (optional third state)
  Future<void> resolve(String alertId) async {
    state = state.copyWith(
      alerts: state.alerts
          .map((a) => a.id == alertId
              ? a.copyWith(isRead: true, status: 'resolved')
              : a)
          .toList(),
    );
    try {
      await Supabase.instance.client.from('sos_messages').update({
        'is_read': true,
        'status': 'resolved',
      }).eq('id', alertId);
    } catch (e) {
      if (kDebugMode) debugPrint('[SOS] resolve error: $e');
    }
  }

  /// Force a fresh fetch (e.g. on pull-to-refresh)
  Future<void> refresh() => _init(arg);
}

// ─────────────────────────────────────────────────────────────
//  Provider
//
//  Usage:
//    // Watch state
//    final sosState = ref.watch(sosAlertProvider(patientId));
//
//    // Read notifier methods
//    ref.read(sosAlertProvider(patientId).notifier).acknowledge(id);
//    ref.read(sosAlertProvider(patientId).notifier).acknowledgeAll();
//    ref.read(sosAlertProvider(patientId).notifier).resolve(id);
//    ref.read(sosAlertProvider(patientId).notifier).refresh();
//
//  Derived getters on SosAlertState:
//    sosState.unread          → List<SosAlert> (pending only, newest first)
//    sosState.unreadCount     → int
//    sosState.latestUnread    → SosAlert? (for top banner)
//    sosState.acknowledged    → List<SosAlert> (for history view)
// ─────────────────────────────────────────────────────────────
final sosAlertProvider =
    NotifierProvider.family<SosAlertNotifier, SosAlertState, String>(
  SosAlertNotifier.new,
);
