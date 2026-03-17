import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _refreshTokenKey = 'supabase_refresh_token';

  /// Save the Supabase refresh token
  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  /// Retrieve the Supabase refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  /// Clear the refresh token on logout or biometric toggle off
  Future<void> clearRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
}
