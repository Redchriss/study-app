import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:studyapp/core/storage/secure_storage.dart';

void main() {
  group('SecureStorage', () {
    late FlutterSecureStorage mockStorage;

    setUp(() {
      mockStorage = const FlutterSecureStorage();
    });

    test('should save and retrieve tokens', () async {
      const testToken = 'test_jwt_token';
      const testRefreshToken = 'test_refresh_token';

      await SecureStorage.saveTokens(testToken, testRefreshToken);

      final retrievedToken = await SecureStorage.getToken();
      final retrievedRefreshToken = await SecureStorage.getRefreshToken();

      expect(retrievedToken, equals(testToken));
      expect(retrievedRefreshToken, equals(testRefreshToken));
    });

    test('should clear tokens', () async {
      await SecureStorage.saveTokens('test_token', 'test_refresh');
      await SecureStorage.clearTokens();

      final token = await SecureStorage.getToken();
      final refreshToken = await SecureStorage.getRefreshToken();

      expect(token, isNull);
      expect(refreshToken, isNull);
    });

    test('hasTokens should return true when tokens exist', () async {
      await SecureStorage.saveTokens('test_token', 'test_refresh');
      final hasTokens = await SecureStorage.hasTokens();
      expect(hasTokens, isTrue);
    });

    test('hasTokens should return false when no tokens exist', () async {
      await SecureStorage.clearTokens();
      final hasTokens = await SecureStorage.hasTokens();
      expect(hasTokens, isFalse);
    });
  });
}
