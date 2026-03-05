import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'device_service.dart';
import 'secure_session_storage.dart';

/// Possible outcomes of a biometric operation.
enum BiometricResult {
  success,
  hardwareUnavailable,
  notEnrolledOnDevice, // OS has no fingerprints registered
  notEnrolledInApp, // no row in biometric_enrollment for this user+device
  lockedOut,
  permanentlyLockedOut,
  cancelled,
  failure,
}

class BiometricService {
  BiometricService({
    required SupabaseClient supabase,
    required DeviceService deviceService,
    required SecureSessionStorage sessionStorage,
  })  : _supabase = supabase,
        _deviceService = deviceService,
        _sessionStorage = sessionStorage;

  final SupabaseClient _supabase;
  final DeviceService _deviceService;
  final SecureSessionStorage _sessionStorage;
  final LocalAuthentication _auth = LocalAuthentication();

  // ─────────────────────────────────────────────
  //  Hardware checks
  // ─────────────────────────────────────────────

  /// Returns true if the device has biometric hardware AND OS‑level fingerprints enrolled.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } on PlatformException {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  Enrollment in Supabase
  // ─────────────────────────────────────────────

  /// Enrolls (or silently ignores duplicate of) this device for [userId].
  /// Call after a successful email/password login.
  Future<void> enrollDevice(String userId) async {
    final deviceId = await _deviceService.getUniqueDeviceId();
    try {
      await _supabase.from('biometric_enrollment').upsert(
        {
          'user_id': userId,
          'device_id': deviceId,
          'enrolled_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,device_id', // ignore if already exists
      );
    } catch (_) {
      // Non-fatal — biometric enroll failure should not block the user
    }
  }

  /// Returns true if a biometric_enrollment row exists for [userId] + this device.
  Future<bool> isDeviceEnrolled(String userId) async {
    final deviceId = await _deviceService.getUniqueDeviceId();
    try {
      final rows = await _supabase
          .from('biometric_enrollment')
          .select('id')
          .eq('user_id', userId)
          .eq('device_id', deviceId)
          .limit(1);
      return (rows as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  //  OS fingerprint prompt
  // ─────────────────────────────────────────────

  Future<BiometricResult> _runOsPrompt() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint to log into MemoCare.',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // allow PIN fallback
          useErrorDialogs: true,
        ),
      );
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'NotAvailable':
          return BiometricResult.hardwareUnavailable;
        case 'NotEnrolled':
          return BiometricResult.notEnrolledOnDevice;
        case 'LockedOut':
          return BiometricResult.lockedOut;
        case 'PermanentlyLockedOut':
          return BiometricResult.permanentlyLockedOut;
        default:
          return BiometricResult.failure;
      }
    } catch (_) {
      return BiometricResult.failure;
    }
  }

  // ─────────────────────────────────────────────
  //  Full biometric login flow
  // ─────────────────────────────────────────────

  /// Full login flow:
  /// 1. Resolve [email] → userId via Postgres RPC.
  /// 2. Check that this device is enrolled for that userId.
  /// 3. Run OS fingerprint prompt.
  /// 4. Restore Supabase session from secure storage.
  ///
  /// Returns [BiometricResult.success] on complete success;
  /// the session will be active in [Supabase.instance.client.auth].
  Future<BiometricResult> loginWithBiometric(String email) async {
    // 1. Resolve userId from email (security-definer RPC, no RLS)
    String? userId;
    try {
      final result = await _supabase.rpc(
        'get_user_id_by_email',
        params: {'p_email': email.trim().toLowerCase()},
      );
      userId = result as String?;
    } catch (_) {}

    if (userId == null || userId.isEmpty) {
      return BiometricResult.notEnrolledInApp;
    }

    // 2. Check device enrollment
    final enrolled = await isDeviceEnrolled(userId);
    if (!enrolled) return BiometricResult.notEnrolledInApp;

    // 3. OS prompt
    final promptResult = await _runOsPrompt();
    if (promptResult != BiometricResult.success) return promptResult;

    // 4. Restore Supabase session
    final session = await _sessionStorage.getUserSession(userId);
    if (session == null) {
      // No stored tokens — user must login with email/password once
      return BiometricResult.notEnrolledInApp;
    }

    try {
      await _supabase.auth.setSession(session.refreshToken);
      return BiometricResult.success;
    } catch (_) {
      // Refresh token expired (rare, ~365 days) — clear and ask email login
      await _sessionStorage.clearUserSession(userId);
      return BiometricResult.notEnrolledInApp;
    }
  }
}
