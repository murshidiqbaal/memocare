import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys used in [FlutterSecureStorage] to persist biometric session state.
/// Nothing here is biometric data — only session tokens and device identity.
class _Keys {
  static const refreshToken = 'memocare_refresh_token';
  static const accessToken = 'memocare_access_token';
  static const deviceId = 'memocare_device_id';
  static const biometricEnabled = 'memocare_biometric_enabled';
  static const patientUserId = 'memocare_patient_user_id';
}

/// Secure local storage for session tokens and biometric preferences.
///
/// Uses [FlutterSecureStorage] which encrypts data with:
///   - Android: EncryptedSharedPreferences (AES-256)
///   - iOS:     Keychain
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ──────────────────────── SESSION TOKENS ────────────────────────────────

  /// Persist both Supabase session tokens after successful login.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _Keys.accessToken, value: accessToken),
      _storage.write(key: _Keys.refreshToken, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() => _storage.read(key: _Keys.accessToken);

  Future<String?> getRefreshToken() => _storage.read(key: _Keys.refreshToken);

  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _Keys.accessToken),
      _storage.delete(key: _Keys.refreshToken),
    ]);
  }

  // ──────────────────────── DEVICE ID ─────────────────────────────────────

  Future<void> saveDeviceId(String deviceId) =>
      _storage.write(key: _Keys.deviceId, value: deviceId);

  Future<String?> getDeviceId() => _storage.read(key: _Keys.deviceId);

  // ──────────────────────── USER ID ───────────────────────────────────────

  Future<void> savePatientUserId(String userId) =>
      _storage.write(key: _Keys.patientUserId, value: userId);

  Future<String?> getPatientUserId() => _storage.read(key: _Keys.patientUserId);

  // ──────────────────────── BIOMETRIC PREFERENCE ──────────────────────────

  Future<void> setBiometricEnabled(bool enabled) =>
      _storage.write(key: _Keys.biometricEnabled, value: enabled.toString());

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _Keys.biometricEnabled);
    return value == 'true';
  }

  // ──────────────────────── FULL WIPE ─────────────────────────────────────

  /// Called on explicit sign-out — clears ALL locally stored biometric state.
  /// Biometric is disabled for the session until the patient re-enables it.
  Future<void> clearAll() => _storage.deleteAll();
}
