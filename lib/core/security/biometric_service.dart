import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

/// Result of a biometric authentication attempt.
enum BiometricResult {
  success,
  failed,
  cancelled,
  notAvailable,
  notEnrolled,
  lockedOut,
  error,
}

/// Core service for fingerprint / face-unlock interactions.
///
/// Uses [LocalAuthentication] from the `local_auth` package.
/// Fingerprint data is NEVER stored — auth is purely local device security.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  // ───────────────────────────── Availability ─────────────────────────────

  /// Returns true when the device hardware supports biometrics AND
  /// the user has at least one enrolled fingerprint / face.
  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      if (!canCheck || !isDeviceSupported) return false;

      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Returns the list of enrolled biometric types (fingerprint, face, etc.).
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ──────────────────────────── Authenticate ───────────────────────────────

  /// Shows the native biometric prompt to the user.
  ///
  /// Uses dementia-friendly plain language.
  Future<BiometricResult> authenticate() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'Touch the fingerprint button to open MemoCare',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device PIN as fallback
          stickyAuth: true, // keep prompt even if app loses focus
          sensitiveTransaction: true,
          useErrorDialogs: true,
        ),
      );
      return authenticated ? BiometricResult.success : BiometricResult.failed;
    } on PlatformException catch (e) {
      return _mapPlatformException(e);
    } catch (_) {
      return BiometricResult.error;
    }
  }

  /// Map [PlatformException] codes to a typed [BiometricResult].
  BiometricResult _mapPlatformException(PlatformException e) {
    switch (e.code) {
      case auth_error.notAvailable:
        return BiometricResult.notAvailable;
      case auth_error.notEnrolled:
        return BiometricResult.notEnrolled;
      case auth_error.lockedOut:
      case auth_error.permanentlyLockedOut:
        return BiometricResult.lockedOut;
      case auth_error.passcodeNotSet:
        return BiometricResult.notEnrolled;
      default:
        return BiometricResult.error;
    }
  }

  /// Human-readable message for the patient (dementia-friendly).
  String resultMessage(BiometricResult result) {
    switch (result) {
      case BiometricResult.success:
        return 'Welcome back! MemoCare is open.';
      case BiometricResult.failed:
        return 'Fingerprint not recognised. Please try again.';
      case BiometricResult.cancelled:
        return 'Login cancelled.';
      case BiometricResult.notAvailable:
        return 'Your phone does not have a fingerprint sensor.';
      case BiometricResult.notEnrolled:
        return 'No fingerprint is set up on this phone. Please use your password.';
      case BiometricResult.lockedOut:
        return 'Too many attempts. Please use your password instead.';
      case BiometricResult.error:
        return 'Something went wrong. Please use your password.';
    }
  }

  /// Cancels any pending biometric authentication dialog.
  Future<void> cancelAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
