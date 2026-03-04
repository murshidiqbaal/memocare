import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/security/biometric_service.dart';
import '../core/security/device_id_service.dart';
import '../core/security/secure_storage_service.dart';
import '../providers/service_providers.dart';

// ─────────────────────────── Singleton Providers ─────────────────────────────

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  return DeviceIdService();
});

// ─────────────────────── Biometric availability check ───────────────────────

/// True when the device hardware can perform biometric auth AND has enrolled data.
final biometricAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(biometricServiceProvider).isAvailable();
});

// ────────────────────── Biometric preference state ───────────────────────────

/// Checks SecureStorage: did the patient previously enable biometric on THIS device?
final biometricEnabledProvider = FutureProvider<bool>((ref) async {
  return ref.watch(secureStorageServiceProvider).isBiometricEnabled();
});

// ────────────────────── Biometric Controller ─────────────────────────────────

/// Encapsulates all biometric enrollment + login logic.
class BiometricController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  BiometricService get _bio => ref.read(biometricServiceProvider);
  SecureStorageService get _storage => ref.read(secureStorageServiceProvider);
  DeviceIdService get _deviceId => ref.read(deviceIdServiceProvider);
  SupabaseClient get _supabase => ref.read(supabaseClientProvider);

  // ─── Step 1: Enable biometric after first password login ─────────────────

  /// Called from [EnableBiometricDialog] after password login succeeds.
  ///
  /// 1. Verifies biometric is available on this device.
  /// 2. Does a single biometric confirmation to prove enrollment.
  /// 3. Stores tokens + device ID in SecureStorage.
  /// 4. Updates `patients` table in Supabase (biometric_enabled, trusted_device_id).
  Future<String?> enableBiometric(String patientId) async {
    state = const AsyncLoading();
    try {
      // 1. Check availability
      final available = await _bio.isAvailable();
      if (!available) {
        state = const AsyncData(null);
        return 'Your device does not support fingerprint unlock.';
      }

      // 2. One-time biometric confirmation
      final result = await _bio.authenticate();
      if (result != BiometricResult.success) {
        state = const AsyncData(null);
        return _bio.resultMessage(result);
      }

      // 3. Persist session tokens
      final session = _supabase.auth.currentSession;
      if (session == null) {
        state = const AsyncData(null);
        return 'Session expired. Please log in again.';
      }
      await _storage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );

      // 4. Persist device ID + preference flag
      final deviceId = await _deviceId.getDeviceId();
      await _storage.saveDeviceId(deviceId);
      await _storage.setBiometricEnabled(true);
      await _storage.savePatientUserId(patientId);

      // 5. Update Supabase `patients` record (no biometric data stored)
      await _supabase.from('patients').update({
        'biometric_enabled': true,
        'trusted_device_id': deviceId,
        'last_biometric_login': DateTime.now().toIso8601String(),
      }).eq('id', patientId);

      state = const AsyncData(null);
      return null; // null = success
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return 'Failed to enable fingerprint: $e';
    }
  }

  // ─── Step 2: Biometric login on future app launches ──────────────────────

  /// Returns null on success, or an error message string.
  ///
  /// 1. Reads local biometric preference.
  /// 2. Compares device ID against Supabase stored trusted_device_id.
  /// 3. Prompts fingerprint.
  /// 4. Restores Supabase session using stored refresh token.
  Future<String?> loginWithBiometric() async {
    state = const AsyncLoading();
    try {
      // Check local flag
      final localEnabled = await _storage.isBiometricEnabled();
      if (!localEnabled) {
        state = const AsyncData(null);
        return 'Fingerprint login is not enabled.';
      }

      // Verify device match
      final storedDeviceId = await _storage.getDeviceId();
      final currentDeviceId = await _deviceId.getDeviceId();
      if (storedDeviceId == null || storedDeviceId != currentDeviceId) {
        // Disable biometric silently — the patient is on a different device
        await _disableBiometricLocally();
        state = const AsyncData(null);
        return 'This is a new device. Please log in with your password.';
      }

      // Check Supabase record
      final patientId = await _storage.getPatientUserId();
      if (patientId != null) {
        final row = await _supabase
            .from('patients')
            .select('biometric_enabled, trusted_device_id')
            .eq('id', patientId)
            .maybeSingle();

        final dbEnabled = row?['biometric_enabled'] as bool? ?? false;
        final dbDeviceId = row?['trusted_device_id'] as String?;

        if (!dbEnabled || dbDeviceId != currentDeviceId) {
          await _disableBiometricLocally();
          state = const AsyncData(null);
          return 'Fingerprint login was disabled. Please use your password.';
        }
      }

      // Prompt fingerprint
      final result = await _bio.authenticate();
      if (result != BiometricResult.success) {
        state = const AsyncData(null);
        return _bio.resultMessage(result);
      }

      // Restore Supabase session
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _disableBiometricLocally();
        state = const AsyncData(null);
        return 'Session expired. Please log in with your password.';
      }

      final response = await _supabase.auth.setSession(refreshToken);
      if (response.session == null) {
        await _disableBiometricLocally();
        state = const AsyncData(null);
        return 'Session could not be restored. Please use your password.';
      }

      // Update stored tokens + last_biometric_login timestamp
      await _storage.saveSession(
        accessToken: response.session!.accessToken,
        refreshToken: response.session!.refreshToken ?? refreshToken,
      );

      if (patientId != null) {
        await _supabase.from('patients').update({
          'last_biometric_login': DateTime.now().toIso8601String(),
        }).eq('id', patientId);
      }

      state = const AsyncData(null);
      return null; // null = success
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
      return 'Fingerprint login failed: $e';
    }
  }

  // ─── Disable biometric (logout, settings toggle, new device) ─────────────

  /// Disable biometric in Supabase and clear all local secure storage.
  Future<void> disableBiometric(String patientId) async {
    state = const AsyncLoading();
    try {
      await _disableBiometricLocally();
      await _supabase.from('patients').update({
        'biometric_enabled': false,
        'trusted_device_id': null,
      }).eq('id', patientId);
      state = const AsyncData(null);
    } catch (e) {
      state = AsyncError(e, StackTrace.current);
    }
  }

  Future<void> _disableBiometricLocally() async {
    await _storage.setBiometricEnabled(false);
    await _storage.clearSession();
  }

  /// Called on explicit sign-out — kills biometric session completely.
  Future<void> onSignOut() async {
    await _storage.clearAll();
  }
}

final biometricControllerProvider =
    AsyncNotifierProvider<BiometricController, void>(BiometricController.new);
