import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:studyapp/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    setUp(() async {
      // Load test environment
      await dotenv.load(fileName: '.env');
    });

    test('should load API URL from environment', () {
      final apiUrl = AppConfig.apiUrl;
      expect(apiUrl, isNotEmpty);
      expect(apiUrl, contains('http'));
    });

    test('should load GraphQL URL from environment', () {
      final graphqlUrl = AppConfig.graphqlUrl;
      expect(graphqlUrl, isNotEmpty);
      expect(graphqlUrl, contains('graphql'));
    });

    test('should have default Sentry environment', () {
      final env = AppConfig.sentryEnvironment;
      expect(env, isNotEmpty);
    });

    test('should parse firebase enabled flag', () {
      final enabled = AppConfig.firebaseEnabled;
      expect(enabled, isA<bool>());
    });
  });
}
