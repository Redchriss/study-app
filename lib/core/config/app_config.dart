import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await dotenv.load(fileName: '.env');
    } catch (e, st) {
      // Release APK must still start if .env is missing or mis-packaged; getters use defaults.
      debugPrint('AppConfig: could not load .env ($e)');
      debugPrint('$st');
    } finally {
      _initialized = true;
    }
  }

  static String get apiUrl {
    try {
      return dotenv.env['API_URL'] ?? 'https://yaza-ai-tutor-r7kb.onrender.com';
    } catch (_) {
      return 'https://yaza-ai-tutor-r7kb.onrender.com';
    }
  }

  static String get graphqlUrl {
    try {
      return dotenv.env['GRAPHQL_URL'] ?? '$apiUrl/graphql/';
    } catch (_) {
      return '$apiUrl/graphql/';
    }
  }

  static String get sentryDsn {
    try {
      return dotenv.env['SENTRY_DSN'] ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get sentryEnvironment {
    try {
      return dotenv.env['SENTRY_ENVIRONMENT'] ?? 'development';
    } catch (_) {
      return 'development';
    }
  }

  static bool get firebaseEnabled {
    try {
      return dotenv.env['FIREBASE_ENABLED'] == 'true';
    } catch (_) {
      // Tests and one-off scripts may read config before dotenv.load().
      return false;
    }
  }
}
