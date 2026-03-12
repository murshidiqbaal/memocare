import 'package:memocare/data/models/sos_alert.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/sos_repository.dart';
import '../providers/auth_provider.dart';

/// Provider for active alerts (patient view)
final myActiveAlertsProvider =
    FutureProvider.autoDispose<List<SosAlert>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final repository = ref.watch(sosRepositoryProvider);
  final alert = await repository.getActiveAlert(user.id);
  return alert != null ? [alert] : [];
});

/// Provider for linked patients' active alerts (caregiver view)
final linkedPatientsAlertsProvider =
    FutureProvider.autoDispose<List<SosAlert>>((ref) async {
  final repository = ref.watch(sosRepositoryProvider);
  return repository.getLinkedPatientsActiveAlerts();
});

/// Stream provider for real-time alerts (caregiver view)
final linkedPatientsAlertsStreamProvider =
    StreamProvider.autoDispose<List<SosAlert>>((ref) {
  final repository = ref.watch(sosRepositoryProvider);
  return repository.watchLinkedPatientsAlerts();
});

/// State notifier for managing SOS countdown and sending
class EmergencySOSController extends StateNotifier<EmergencySOSState> {
  final SosRepository _repository;
  final Ref _ref;

  EmergencySOSController(this._repository, this._ref)
      : super(const EmergencySOSState.idle());

  /// Start SOS countdown
  void startCountdown() {
    state = const EmergencySOSState.countdown(5);
    _runCountdown();
  }

  /// Cancel countdown
  void cancelCountdown() {
    state = const EmergencySOSState.cancelled();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) state = const EmergencySOSState.idle();
    });
  }

  Future<void> _runCountdown() async {
    for (int i = 5; i > 0; i--) {
      if (!mounted || state is! EmergencySOSCountdown) return;
      state = EmergencySOSState.countdown(i);
      await Future.delayed(const Duration(seconds: 1));
    }
    if (mounted && state is EmergencySOSCountdown) {
      await _sendSOS();
    }
  }

  Future<void> _sendSOS() async {
    state = const EmergencySOSState.sending();

    final result = await _repository.sendEmergencyAlert();

    result.fold(
      (failure) {
        state = EmergencySOSState.error(failure.message);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) state = const EmergencySOSState.idle();
        });
      },
      (alert) {
        state = EmergencySOSState.sent(alert);
        _ref.invalidate(myActiveAlertsProvider);
        _ref.invalidate(linkedPatientsAlertsProvider);
        _ref.invalidate(linkedPatientsAlertsStreamProvider);

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) state = const EmergencySOSState.idle();
        });
      },
    );
  }

  Future<void> resolveAlert(String alertId) async {
    await _repository.resolveSosAlert(alertId);
    _ref.invalidate(myActiveAlertsProvider);
    _ref.invalidate(linkedPatientsAlertsProvider);
    _ref.invalidate(linkedPatientsAlertsStreamProvider);
  }
}

final emergencySOSControllerProvider = StateNotifierProvider.autoDispose<
    EmergencySOSController, EmergencySOSState>((ref) {
  final repository = ref.watch(sosRepositoryProvider);
  return EmergencySOSController(repository, ref);
});

sealed class EmergencySOSState {
  const EmergencySOSState();
  const factory EmergencySOSState.idle() = EmergencySOSIdle;
  const factory EmergencySOSState.countdown(int seconds) =
      EmergencySOSCountdown;
  const factory EmergencySOSState.sending() = EmergencySOSSending;
  const factory EmergencySOSState.sent(SosAlert alert) = EmergencySOSSent;
  const factory EmergencySOSState.cancelled() = EmergencySOSCancelled;
  const factory EmergencySOSState.error(String message) = EmergencySOSError;
}

class EmergencySOSIdle extends EmergencySOSState {
  const EmergencySOSIdle();
}

class EmergencySOSCountdown extends EmergencySOSState {
  final int seconds;
  const EmergencySOSCountdown(this.seconds);
}

class EmergencySOSSending extends EmergencySOSState {
  const EmergencySOSSending();
}

class EmergencySOSSent extends EmergencySOSState {
  final SosAlert alert;
  const EmergencySOSSent(this.alert);
}

class EmergencySOSCancelled extends EmergencySOSState {
  const EmergencySOSCancelled();
}

class EmergencySOSError extends EmergencySOSState {
  final String message;
  const EmergencySOSError(this.message);
}
