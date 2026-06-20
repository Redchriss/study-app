import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _installKey = 'app_install_id';

  /// Check if this is a fresh install and clear any stale Keychain data.
  static Future<void> ensureFreshInstall() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final installId = prefs.getString(_installKey);
      if (installId == null) {
        // First launch after install — clear any stale tokens from Keychain
        await _storage.deleteAll();
        await prefs.setString(_installKey, DateTime.now().toIso8601String());
      }
    } catch (_) {
      // Non-critical: if this fails, stale tokens may persist on iOS reinstall
    }
  }

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
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _refreshKey);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearTokens() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {
      // If secure storage is unavailable or corrupted, treat it as already cleared.
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
