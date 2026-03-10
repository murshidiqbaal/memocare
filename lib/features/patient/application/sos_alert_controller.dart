import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sos_repository.dart';

class SosAlertState {
  final int countdownSeconds;
  final bool isSending;
  final String? errorMessage;
  final bool isSuccess;

  SosAlertState({
    this.countdownSeconds = 5,
    this.isSending = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SosAlertState copyWith({
    int? countdownSeconds,
    bool? isSending,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SosAlertState(
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SosAlertController extends StateNotifier<SosAlertState> {
  final PatientSosRepository _repository;
  Timer? _timer;

  SosAlertController(this._repository) : super(SosAlertState());

  void startCountdown() {
    _timer?.cancel();
    state = state.copyWith(
        countdownSeconds: 5, errorMessage: null, isSuccess: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.countdownSeconds > 1) {
        state = state.copyWith(countdownSeconds: state.countdownSeconds - 1);
      } else {
        timer.cancel();
        sendSOSAlert();
      }
    });
  }

  void cancelCountdown() {
    _timer?.cancel();
    state = state.copyWith(countdownSeconds: 5);
  }

  Future<void> sendSOSAlert({String? note}) async {
    if (state.isSending) return;

    _timer?.cancel();
    state = state.copyWith(
        isSending: true, errorMessage: null, countdownSeconds: 0);

    try {
      await _repository.sendSOSAlert(note: note);
      if (mounted) {
        state = state.copyWith(isSending: false, isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isSending: false, errorMessage: e.toString());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final sosAlertControllerProvider =
    StateNotifierProvider.autoDispose<SosAlertController, SosAlertState>((ref) {
  final repository = ref.watch(patientSosRepositoryProvider);
  return SosAlertController(repository);
});
