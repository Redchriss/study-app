import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  static const _tokenKey = 'jwt_token';
  static const _refreshKey = 'refresh_token';

  static Future<void> saveTokens(String token, String refreshToken) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _refreshKey, value: refreshToken);
    } catch (e) {
      throw Exception('Failed to save tokens securely: $e');
    }
  }

  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      throw Exception('Failed to read token: $e');
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshKey);
    } catch (e) {
      throw Exception('Failed to read refresh token: $e');
    }
  }

  static Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshKey);
    } catch (e) {
      throw Exception('Failed to clear tokens: $e');
    }
  }

  static Future<bool> hasTokens() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
