import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/emergency_alert.dart';
import '../data/repositories/emergency_alert_repository.dart';
import 'service_providers.dart';

/// Provider for Emergency Alert Repository
final emergencyAlertRepositoryProvider =
    Provider<EmergencyAlertRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return EmergencyAlertRepository(supabase);
});

/// Provider for active alerts (patient view)
final myActiveAlertsProvider =
    FutureProvider.autoDispose<List<EmergencyAlert>>((ref) async {
  final repository = ref.watch(emergencyAlertRepositoryProvider);
  return repository.getMyActiveAlerts();
});

/// Provider for linked patients' active alerts (caregiver view)
final linkedPatientsAlertsProvider =
    FutureProvider.autoDispose<List<EmergencyAlert>>((ref) async {
  final repository = ref.watch(emergencyAlertRepositoryProvider);
  return repository.getLinkedPatientsActiveAlerts();
});

/// Stream provider for real-time alerts (caregiver view)
final linkedPatientsAlertsStreamProvider =
    StreamProvider.autoDispose<List<EmergencyAlert>>((ref) {
  final repository = ref.watch(emergencyAlertRepositoryProvider);
  return repository.watchLinkedPatientsAlerts();
});

/// Provider for alert history
final alertHistoryProvider =
    FutureProvider.autoDispose<List<EmergencyAlert>>((ref) async {
  final repository = ref.watch(emergencyAlertRepositoryProvider);
  return repository.getAlertHistory();
});

/// State notifier for managing SOS countdown and sending
class EmergencySOSController extends StateNotifier<EmergencySOSState> {
  final EmergencyAlertRepository _repository;
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
    // Reset to idle after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        state = const EmergencySOSState.idle();
      }
    });
  }

  /// Run countdown timer
  Future<void> _runCountdown() async {
    for (int i = 5; i > 0; i--) {
      if (!mounted || state is! EmergencySOSCountdown) return;

      state = EmergencySOSState.countdown(i);
      await Future.delayed(const Duration(seconds: 1));
    }

    // Countdown complete - send SOS
    if (mounted && state is EmergencySOSCountdown) {
      await _sendSOS();
    }
  }

  /// Send SOS alert
  Future<void> _sendSOS() async {
    state = const EmergencySOSState.sending();

    final result = await _repository.sendEmergencyAlert();

    result.fold(
      (failure) {
        state = EmergencySOSState.error(failure.message);

        // Reset to idle after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            state = const EmergencySOSState.idle();
          }
        });
      },
      (alert) {
        state = EmergencySOSState.sent(alert);

        // Initiate call to caregiver immediately
        _callCaregiver();

        // Refresh alerts list
        _ref.invalidate(myActiveAlertsProvider);
        _ref.invalidate(linkedPatientsAlertsProvider);

        // Reset to idle after showing success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            state = const EmergencySOSState.idle();
          }
        });
      },
    );
  }

  /// Resolve an alert (caregiver action)
  Future<void> resolveAlert(String alertId) async {
    final result = await _repository.resolveEmergencyAlert(alertId);

    result.fold(
      (failure) => print('Failed to resolve alert: ${failure.message}'),
      (_) {
        _ref.invalidate(linkedPatientsAlertsProvider);
        _ref.invalidate(linkedPatientsAlertsStreamProvider);
      },
    );
  }

  /// Automatically call primary caregiver
  Future<void> _callCaregiver() async {
    final result = await _repository.getPrimaryCaregiverPhone();

    result.fold(
      (failure) => print('Could not get caregiver phone: ${failure.message}'),
      (phone) async {
        if (phone != null && phone.isNotEmpty) {
          final Uri launchUri = Uri(
            scheme: 'tel',
            path: phone,
          );
          try {
            if (await canLaunchUrl(launchUri)) {
              await launchUrl(launchUri);
            }
          } catch (e) {
            print('Error launching call: $e');
          }
        }
      },
    );
  }
}

/// Provider for Emergency SOS Controller
final emergencySOSControllerProvider = StateNotifierProvider.autoDispose<
    EmergencySOSController, EmergencySOSState>((ref) {
  final repository = ref.watch(emergencyAlertRepositoryProvider);
  return EmergencySOSController(repository, ref);
});

/// Emergency SOS State
sealed class EmergencySOSState {
  const EmergencySOSState();

  const factory EmergencySOSState.idle() = EmergencySOSIdle;
  const factory EmergencySOSState.countdown(int seconds) =
      EmergencySOSCountdown;
  const factory EmergencySOSState.sending() = EmergencySOSSending;
  const factory EmergencySOSState.sent(EmergencyAlert alert) = EmergencySOSSent;
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
  final EmergencyAlert alert;
  const EmergencySOSSent(this.alert);
}

class EmergencySOSCancelled extends EmergencySOSState {
  const EmergencySOSCancelled();
}

class EmergencySOSError extends EmergencySOSState {
  final String message;
  const EmergencySOSError(this.message);
}
