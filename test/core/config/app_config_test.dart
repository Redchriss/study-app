import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:studyapp/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    setUp(() {
      dotenv.testLoad(
        fileInput: '''
API_URL=https://test.yaza.local
GRAPHQL_URL=https://test.yaza.local/graphql/
SENTRY_ENVIRONMENT=test
FIREBASE_ENABLED=true
''',
      );
    });

    test('should load API URL from environment', () {
      final apiUrl = AppConfig.apiUrl;
      expect(apiUrl, 'https://test.yaza.local');
    });

    test('should load GraphQL URL from environment', () {
      final graphqlUrl = AppConfig.graphqlUrl;
      expect(graphqlUrl, 'https://test.yaza.local/graphql/');
    });

    test('should have default Sentry environment', () {
      final env = AppConfig.sentryEnvironment;
      expect(env, 'test');
    });

    test('should parse firebase enabled flag', () {
      final enabled = AppConfig.firebaseEnabled;
      expect(enabled, isTrue);
    });

    test('should fall back safely when .env is missing', () {
      dotenv.clean();

      expect(AppConfig.apiUrl, 'https://yaza-ai-tutor-r7kb.onrender.com');
      expect(
        AppConfig.graphqlUrl,
        'https://yaza-ai-tutor-r7kb.onrender.com/graphql/',
      );
      expect(AppConfig.sentryDsn, isEmpty);
      expect(AppConfig.sentryEnvironment, 'development');
      expect(AppConfig.firebaseEnabled, isFalse);
    });
  });
}
