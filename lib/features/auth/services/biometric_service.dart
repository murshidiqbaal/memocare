import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Typed result returned by [BiometricService.authenticate].
enum BiometricAuthResult {
  success,
  notAvailable,
  notEnrolled,
  lockedOut,
  permanentlyLockedOut,
  cancelled,
  failure,
}

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if the device has biometric hardware AND at least
  /// one biometric (fingerprint / face) is enrolled.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (!canCheck && !isSupported) return false;

      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the user for biometric authentication and returns a typed result.
  Future<BiometricAuthResult> authenticate() async {
    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Please authenticate',
        biometricOnly: true,
        //stickyAuth: true,
      );
      return didAuthenticate
          ? BiometricAuthResult.success
          : BiometricAuthResult.cancelled;
    } on PlatformException catch (e) {
      final code = e.code.toString();
      if (code == 'NotAvailable') return BiometricAuthResult.notAvailable;
      if (code == 'NotEnrolled') return BiometricAuthResult.notEnrolled;
      if (code == 'LockedOut') return BiometricAuthResult.lockedOut;
      if (code == 'PermanentlyLockedOut')
        return BiometricAuthResult.permanentlyLockedOut;
      if (code == 'userCancelled') return BiometricAuthResult.cancelled;
      return BiometricAuthResult.failure;
    } catch (_) {
      return BiometricAuthResult.failure;
    }
  }
}
