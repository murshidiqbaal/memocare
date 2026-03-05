import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted, encrypted session tokens — used for biometric login session restore.
class SecureSessionStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ── Legacy key (keep for backward compat) ──
  static const String _sessionKey = 'supabase_auth_session';

  Future<void> saveSession(String sessionJson) async =>
      _storage.write(key: _sessionKey, value: sessionJson);

  Future<String?> getSession() => _storage.read(key: _sessionKey);

  Future<void> clearSession() => _storage.delete(key: _sessionKey);

  // ── Per-user token storage (keyed by userId) ──

  String _accessKey(String userId) => 'access_$userId';
  String _refreshKey(String userId) => 'refresh_$userId';

  /// Persist tokens after a successful email/password login.
  Future<void> saveUserSession(
    String userId, {
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessKey(userId), value: accessToken),
      _storage.write(key: _refreshKey(userId), value: refreshToken),
    ]);
  }

  /// Retrieve tokens for [userId]. Returns null if never saved.
  Future<({String accessToken, String refreshToken})?> getUserSession(
      String userId) async {
    final access = await _storage.read(key: _accessKey(userId));
    final refresh = await _storage.read(key: _refreshKey(userId));
    if (access == null || refresh == null) return null;
    return (accessToken: access, refreshToken: refresh);
  }

  /// Remove tokens for [userId] (call on logout / re-enroll).
  Future<void> clearUserSession(String userId) async {
    await Future.wait([
      _storage.delete(key: _accessKey(userId)),
      _storage.delete(key: _refreshKey(userId)),
    ]);
  }
}
