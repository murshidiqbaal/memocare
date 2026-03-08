// lib/providers/sos_provider.dart
//
// ─── SOS Riverpod Providers ───────────────────────────────────────────────────
//
// Three provider layers:
//
//  1. sosControllerProvider          — StateNotifier that drives the SOS flow
//     (idle → sending → sent / error) for the PATIENT side.
//
//  2. caregiverSosStreamProvider     — StreamProvider for the CAREGIVER side.
//     Subscribes to active sos_alerts WHERE caregiver_id = current user.
//
//  3. sosPendingCountProvider        — derived int provider (badge count).
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dementia_care_app/core/services/call_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/sos_alert.dart';
import '../data/repositories/sos_repository.dart';
import 'connection_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 1 — SOS CONTROLLER (patient side)
// ─────────────────────────────────────────────────────────────────────────────

/// Patient SOS send state
sealed class SosState {
  const SosState();
}

class SosIdle extends SosState {
  const SosIdle();
}

class SosSending extends SosState {
  const SosSending();
}

/// Sent successfully — [sent] = how many rows were inserted.
class SosSent extends SosState {
  final int sent;
  final bool wasQueued;
  const SosSent({required this.sent, this.wasQueued = false});
}

class SosError extends SosState {
  final String message;
  const SosError(this.message);
}

// ─────────────────────────────────────────────────────────────────────────────

class SosController extends StateNotifier<SosState> {
  final SosRepository _repo;
  final CallService _callService;
  final Ref _ref;

  SosController(this._repo, this._callService, this._ref)
      : super(const SosIdle());

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Called after the patient countdown completes.
  /// [customMessage] is optional — defaults to 'SOS emergency triggered'.
  Future<void> triggerSOS({String? customMessage}) async {
    if (state is SosSending) return; // deduplicate parallel taps

    state = const SosSending();

    final result = await _repo.triggerSOS(
      message: customMessage ?? 'SOS emergency triggered',
    );

    if (result.isSuccess || result.queued) {
      state = SosSent(sent: result.sent, wasQueued: result.queued);

      // 📞 Auto-initiate call to primary caregiver if not already offline-queued
      if (!result.queued) {
        _callCaregiver();
      }

      // Auto-reset to idle after showing success for 4 seconds
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) state = const SosIdle();
    } else {
      state = SosError(result.error ?? 'Unknown error');
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) state = const SosIdle();
    }
  }

  /// Reset to idle (e.g., user dismissed error).
  void reset() => state = const SosIdle();

  // ── Private Helpers ────────────────────────────────────────────────────────

  /// Fetch first linked caregiver and initiate call
  Future<void> _callCaregiver() async {
    try {
      final caregivers = await _ref.read(linkedCaregiversProvider.future);
      if (caregivers.isNotEmpty) {
        final phone = caregivers.first.phone;
        if (phone != null && phone.isNotEmpty) {
          await _callService.initiateCall(phone);
        }
      }
    } catch (e) {
      if (kDebugMode) print('[SosController] 📞 Call failed: $e');
    }
  }
}

/// AutoDispose — the controller is only alive while the SOS screen is open.
final sosControllerProvider =
    StateNotifierProvider.autoDispose<SosController, SosState>((ref) {
  final repo = ref.watch(sosRepositoryProvider);
  final callService = ref.watch(callServiceProvider);
  return SosController(repo, callService, ref);
});

// ─────────────────────────────────────────────────────────────────────────────
// 2 — CAREGIVER SOS STREAM PROVIDER
// ─────────────────────────────────────────────────────────────────────────────

/// Real-time stream of active SOS alerts directed at the current caregiver.
/// Backed by Supabase `.stream()` — auto-reacts to INSERT/UPDATE/DELETE.
final caregiverSosStreamProvider =
    StreamProvider.autoDispose<List<SosAlert>>((ref) {
  final repo = ref.watch(sosRepositoryProvider);
  return repo.watchAlertsForCaregiver();
});

// ─────────────────────────────────────────────────────────────────────────────
// 3 — BADGE COUNT (derived)
// ─────────────────────────────────────────────────────────────────────────────

/// Derived count used for the caregiver nav-bar badge.
/// Returns 0 when loading or on error — never crashes.
final sosBadgeCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(caregiverSosStreamProvider).maybeWhen(
        data: (alerts) => alerts.length,
        orElse: () => 0,
      );
});

// ─────────────────────────────────────────────────────────────────────────────
// 4 — ACKNOWLEDGE / RESOLVE ACTIONS (helpers consumed by UI)
// ─────────────────────────────────────────────────────────────────────────────

/// Acknowledge a specific alert. Call via `ref.read(sosAcknowledgeProvider)(id)`.
final sosAcknowledgeProvider =
    Provider.autoDispose<Future<void> Function(String)>(
  (ref) {
    final repo = ref.watch(sosRepositoryProvider);
    return (String alertId) => repo.acknowledgeAlert(alertId);
  },
);

/// Resolve a specific alert.
final sosResolveProvider = Provider.autoDispose<Future<void> Function(String)>(
  (ref) {
    final repo = ref.watch(sosRepositoryProvider);
    return (String alertId) => repo.resolveAlert(alertId);
  },
);
