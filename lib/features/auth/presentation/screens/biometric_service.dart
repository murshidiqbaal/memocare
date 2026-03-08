import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to log into MemoCare securely.',
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
          // Biometric hardware not available
          break;
        case 'NotEnrolled':
          // No biometrics enrolled on device
          break;
        case 'LockedOut':
          // Too many failed attempts, temporarily locked
          break;
        case 'PermanentlyLockedOut':
          // Permanently locked, user must unlock via settings
          break;
        case 'otherOperatingSystem':
          // Unsupported OS
          break;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
