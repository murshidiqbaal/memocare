import 'package:dementia_care_app/features/auth/providers/auth_provider.dart';
import 'package:dementia_care_app/features/auth/services/biometric_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ─── Storage keys ────────────────────────────────────────────────────────────
const _kEmail = 'bio_email';
const _kPassword = 'bio_password';
const _kEnabled = 'bio_enabled';

// ─── SecureStorage singleton ─────────────────────────────────────────────────
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// ─── BiometricService ─────────────────────────────────────────────────────────
final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

// ─── Hardware availability ────────────────────────────────────────────────────
/// True when device hardware supports biometrics AND has enrolled biometrics.
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.watch(biometricServiceProvider).isBiometricAvailable();
});

// ─── User preference (enabled / disabled) ────────────────────────────────────
/// True when the user previously chose to enable biometric login.
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final value = await storage.read(key: _kEnabled);
  return value == 'true';
});

// ─── Helper: save / clear credential helpers ─────────────────────────────────
/// Writes email + password + enabled flag to secure storage.
/// Call this after a successful email/password login.
Future<void> saveCredentials(
  FlutterSecureStorage storage, {
  required String email,
  required String password,
}) async {
  await Future.wait([
    storage.write(key: _kEmail, value: email),
    storage.write(key: _kPassword, value: password),
    storage.write(key: _kEnabled, value: 'true'),
  ]);
}

/// Removes all stored biometric credentials.
Future<void> clearCredentials(FlutterSecureStorage storage) async {
  await Future.wait([
    storage.delete(key: _kEmail),
    storage.delete(key: _kPassword),
    storage.delete(key: _kEnabled),
  ]);
}

// ─── Biometric login state ────────────────────────────────────────────────────
enum BiometricLoginStatus { idle, loading, success, failure }

class BiometricLoginState {
  const BiometricLoginState({
    this.status = BiometricLoginStatus.idle,
    this.errorMessage,
  });

  final BiometricLoginStatus status;
  final String? errorMessage;

  bool get isLoading => status == BiometricLoginStatus.loading;
  bool get isSuccess => status == BiometricLoginStatus.success;
  bool get isFailure => status == BiometricLoginStatus.failure;

  BiometricLoginState copyWith({
    BiometricLoginStatus? status,
    String? errorMessage,
  }) {
    return BiometricLoginState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

// ─── BiometricLoginNotifier ───────────────────────────────────────────────────
class BiometricLoginNotifier extends Notifier<BiometricLoginState> {
  @override
  BiometricLoginState build() => const BiometricLoginState();

  /// Full biometric login flow:
  /// 1. Prompt biometric
  /// 2. Read credentials from secure storage
  /// 3. Sign in via Supabase auth repo
  /// 4. Riverpod auth state updates automatically via stream
  Future<void> login() async {
    state = state.copyWith(status: BiometricLoginStatus.loading);

    // Step 1 — biometric prompt
    final biometricService = ref.read(biometricServiceProvider);
    final authResult = await biometricService.authenticate();

    if (authResult != BiometricAuthResult.success) {
      state = state.copyWith(
        status: BiometricLoginStatus.failure,
        errorMessage: _messageFor(authResult),
      );
      return;
    }

    // Step 2 — read stored credentials
    final storage = ref.read(secureStorageProvider);
    final email = await storage.read(key: _kEmail);
    final password = await storage.read(key: _kPassword);

    if (email == null ||
        email.isEmpty ||
        password == null ||
        password.isEmpty) {
      state = state.copyWith(
        status: BiometricLoginStatus.failure,
        errorMessage:
            'No saved credentials found. Please log in with your password first.',
      );
      return;
    }

    // Step 3 — sign in via Supabase
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.signIn(email: email, password: password);

    result.fold(
      (failure) {
        state = state.copyWith(
          status: BiometricLoginStatus.failure,
          errorMessage: failure.message,
        );
      },
      (_) {
        // Step 4 — auth stream updates authStateChangesProvider automatically
        state = state.copyWith(status: BiometricLoginStatus.success);
      },
    );
  }

  void reset() => state = const BiometricLoginState();

  String _messageFor(BiometricAuthResult result) {
    switch (result) {
      case BiometricAuthResult.notAvailable:
        return 'Biometric hardware is not available on this device.';
      case BiometricAuthResult.notEnrolled:
        return 'No biometrics enrolled. Please set up fingerprint in device settings.';
      case BiometricAuthResult.lockedOut:
        return 'Too many failed attempts. Please try again later.';
      case BiometricAuthResult.permanentlyLockedOut:
        return 'Biometrics locked. Please unlock via device settings.';
      case BiometricAuthResult.cancelled:
        return 'Authentication cancelled.';
      default:
        return 'Biometric authentication failed. Please try again.';
    }
  }
}

final biometricLoginProvider =
    NotifierProvider<BiometricLoginNotifier, BiometricLoginState>(
  BiometricLoginNotifier.new,
);
