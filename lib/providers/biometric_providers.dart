import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/biometric_service.dart';
import '../screens/auth/device_service.dart';
import '../screens/auth/secure_session_storage.dart';

// ── Singletons ──────────────────────────────────────────────────────────────

final deviceServiceProvider = Provider<DeviceService>((_) => DeviceService());

final secureSessionStorageProvider =
    Provider<SecureSessionStorage>((_) => SecureSessionStorage());

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService(
    supabase: Supabase.instance.client,
    deviceService: ref.watch(deviceServiceProvider),
    sessionStorage: ref.watch(secureSessionStorageProvider),
  );
});

// ── Availability ─────────────────────────────────────────────────────────────

final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometricServiceProvider).isBiometricAvailable();
});

// ── Login state notifier ─────────────────────────────────────────────────────

enum BiometricLoginStatus { idle, loading, success, error }

class BiometricLoginState {
  const BiometricLoginState({
    this.status = BiometricLoginStatus.idle,
    this.errorMessage,
  });

  final BiometricLoginStatus status;
  final String? errorMessage;

  BiometricLoginState copyWith({
    BiometricLoginStatus? status,
    String? errorMessage,
  }) =>
      BiometricLoginState(
        status: status ?? this.status,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

class BiometricLoginNotifier extends StateNotifier<BiometricLoginState> {
  BiometricLoginNotifier(this._service) : super(const BiometricLoginState());

  final BiometricService _service;

  Future<void> loginWithBiometric(String email) async {
    state = state.copyWith(
        status: BiometricLoginStatus.loading, errorMessage: null);

    final result = await _service.loginWithBiometric(email);

    switch (result) {
      case BiometricResult.success:
        state = state.copyWith(status: BiometricLoginStatus.success);
      case BiometricResult.hardwareUnavailable:
        state = state.copyWith(
          status: BiometricLoginStatus.error,
          errorMessage: 'Biometric hardware is not available on this device.',
        );
      case BiometricResult.notEnrolledOnDevice:
        state = state.copyWith(
          status: BiometricLoginStatus.error,
          errorMessage:
              'No fingerprints are registered on this device. Please set them up in device Settings.',
        );
      case BiometricResult.notEnrolledInApp:
        state = state.copyWith(
          status: BiometricLoginStatus.error,
          errorMessage:
              'No fingerprint login set up for this email on this device. Please log in with your password first.',
        );
      case BiometricResult.lockedOut:
        state = state.copyWith(
          status: BiometricLoginStatus.error,
          errorMessage:
              'Too many failed attempts. Please wait a moment and try again.',
        );
      case BiometricResult.permanentlyLockedOut:
        state = state.copyWith(
          status: BiometricLoginStatus.error,
          errorMessage:
              'Fingerprint is locked. Please unlock your device with your PIN/password first.',
        );
      case BiometricResult.cancelled:
        state = state.copyWith(status: BiometricLoginStatus.idle);
      case BiometricResult.failure:
        state = state.copyWith(
          status: BiometricLoginStatus.error,
          errorMessage: 'Authentication failed. Please try again.',
        );
    }
  }

  void reset() => state = const BiometricLoginState();
}

final biometricLoginProvider = StateNotifierProvider.autoDispose<
    BiometricLoginNotifier, BiometricLoginState>(
  (ref) => BiometricLoginNotifier(ref.watch(biometricServiceProvider)),
);
