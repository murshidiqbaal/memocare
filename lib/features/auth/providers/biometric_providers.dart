import 'package:memocare/features/auth/providers/auth_provider.dart';
import 'package:memocare/features/auth/services/biometric_service.dart';
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

// ─── Check if credentials are saved ──────────────────────────────────────────
/// Returns true if email + password are saved in secure storage.
final biometricCredentialsSavedProvider = FutureProvider<bool>((ref) async {
  final storage = ref.watch(secureStorageProvider);
  final email = await storage.read(key: _kEmail);
  final password = await storage.read(key: _kPassword);

  final saved = email != null &&
      email.isNotEmpty &&
      password != null &&
      password.isNotEmpty;

  print('🔍 Biometric credentials saved: $saved (email: ${email != null})');
  return saved;
});

// ─── Helper: save / clear credential helpers ─────────────────────────────────
/// Writes email + password + enabled flag to secure storage.
/// Call this after a successful email/password login.
Future<void> saveCredentials(
  FlutterSecureStorage storage, {
  required String email,
  required String password,
}) async {
  print('💾 Saving biometric credentials for: $email');
  await Future.wait([
    storage.write(key: _kEmail, value: email),
    storage.write(key: _kPassword, value: password),
    storage.write(key: _kEnabled, value: 'true'),
  ]);
  print('✅ Credentials saved successfully');
}

/// Removes all stored biometric credentials.
Future<void> clearCredentials(FlutterSecureStorage storage) async {
  print('🗑️ Clearing biometric credentials');
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
  /// 1. Check if credentials are saved
  /// 2. Prompt biometric
  /// 3. Read credentials from secure storage
  /// 4. Sign in via Supabase auth repo
  /// 5. Riverpod auth state updates automatically via stream
  Future<void> login() async {
    print('🔐 Starting biometric login...');
    state = state.copyWith(status: BiometricLoginStatus.loading);

    try {
      // Step 1 — check if credentials are saved
      final storage = ref.read(secureStorageProvider);
      final email = await storage.read(key: _kEmail);
      final password = await storage.read(key: _kPassword);

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        print('❌ No saved credentials found');
        state = state.copyWith(
          status: BiometricLoginStatus.failure,
          errorMessage:
              'No saved credentials. Please log in with email/password first.',
        );
        return;
      }

      print('✅ Credentials found. Prompting biometric...');

      // Step 2 — biometric prompt
      final biometricService = ref.read(biometricServiceProvider);
      final authResult = await biometricService.authenticate();

      if (authResult != BiometricAuthResult.success) {
        print('❌ Biometric auth failed: $authResult');
        state = state.copyWith(
          status: BiometricLoginStatus.failure,
          errorMessage: _messageFor(authResult),
        );
        return;
      }

      print('✅ Biometric successful. Signing in...');

      // Step 3 — sign in via Supabase with stored credentials
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signIn(email: email, password: password);

      result.fold(
        (failure) {
          print('❌ Sign in failed: ${failure.message}');
          state = state.copyWith(
            status: BiometricLoginStatus.failure,
            errorMessage: 'Sign in failed: ${failure.message}',
          );
        },
        (_) {
          // Step 4 — auth stream updates authStateChangesProvider automatically
          print('✅ Biometric login successful!');
          state = state.copyWith(status: BiometricLoginStatus.success);
        },
      );
    } catch (e) {
      print('❌ Unexpected error: $e');
      state = state.copyWith(
        status: BiometricLoginStatus.failure,
        errorMessage: 'Unexpected error: $e',
      );
    }
  }

  void reset() {
    print('🔄 Resetting biometric login state');
    state = const BiometricLoginState();
  }

  String _messageFor(BiometricAuthResult result) {
    switch (result) {
      case BiometricAuthResult.notAvailable:
        return 'Biometric hardware not available on this device.';
      case BiometricAuthResult.notEnrolled:
        return 'No biometrics enrolled. Set up fingerprint in device settings.';
      case BiometricAuthResult.lockedOut:
        return 'Too many failed attempts. Try again later.';
      case BiometricAuthResult.permanentlyLockedOut:
        return 'Biometrics locked. Unlock via device settings.';
      case BiometricAuthResult.cancelled:
        return 'Authentication cancelled. Please try again.';
      default:
        return 'Biometric authentication failed. Please try again.';
    }
  }
}

final biometricLoginProvider =
    NotifierProvider<BiometricLoginNotifier, BiometricLoginState>(
  BiometricLoginNotifier.new,
);
