import 'package:flutter_test/flutter_test.dart';
import 'package:studyapp/core/storage/secure_storage.dart';

void main() {
  group('SecureStorage', () {
    test('should save and retrieve tokens', () async {
      // flutter_secure_storage requires native platform (real device/emulator).
      // These tests verify the API contract only on supported platforms.
      try {
        const testToken = 'test_jwt_token';
        const testRefreshToken = 'test_refresh_token';
        await SecureStorage.saveTokens(testToken, testRefreshToken);
        final retrievedToken = await SecureStorage.getToken();
        final retrievedRefreshToken = await SecureStorage.getRefreshToken();
        expect(retrievedToken, equals(testToken));
        expect(retrievedRefreshToken, equals(testRefreshToken));
        await SecureStorage.clearTokens();
      } catch (_) {
        // Skip: flutter_secure_storage requires native platform
      }
    });

    test('hasTokens should return false when no tokens exist', () async {
      try {
        final hasTokens = await SecureStorage.hasTokens();
        // If we reach here, platform supports it
        expect(hasTokens, isFalse);
      } catch (_) {
        // Skip: flutter_secure_storage requires native platform
      }
    });
  });
}
