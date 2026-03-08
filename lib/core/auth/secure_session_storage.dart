import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _sessionKey = 'supabase_auth_session';

  /// Save the Supabase session token
  Future<void> saveSession(String sessionJson) async {
    await _storage.write(key: _sessionKey, value: sessionJson);
  }

  /// Retrieve the Supabase session token
  Future<String?> getSession() async {
    return await _storage.read(key: _sessionKey);
  }

  /// Clear the session on logout or biometric toggle off
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
