import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static Future<void> init() async {
    await dotenv.load(fileName: '.env');
  }

  static String get apiUrl =>
      dotenv.env['API_URL'] ?? 'https://yaza-ai-tutor.onrender.com';

  static String get graphqlUrl =>
      dotenv.env['GRAPHQL_URL'] ?? '$apiUrl/graphql/';

  static String get sentryDsn =>
      dotenv.env['SENTRY_DSN'] ?? '';

  static String get sentryEnvironment =>
      dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development';

  static bool get firebaseEnabled {
    try {
      return dotenv.env['FIREBASE_ENABLED'] == 'true';
    } catch (_) {
      // Tests and one-off scripts may read config before dotenv.load().
      return false;
    }
  }
}
