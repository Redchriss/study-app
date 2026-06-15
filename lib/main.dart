import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';
import 'core/config/app_config.dart';
import 'core/graphql/client.dart';
import 'core/services/analytics_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/retention_service.dart';
import 'core/widgets/widgets.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'router.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();

  // Initialize Sentry if DSN is configured
  if (AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.sentryEnvironment;
        options.tracesSampleRate = 0.1;
      },
      appRunner: () async => _runApp(),
    );
  } else {
    await _runApp();
  }
}

Future<void> _runApp() async {
  // Initialize error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    Sentry.captureException(details.exception, stackTrace: details.stack);
  };

  ErrorWidget.builder = (details) {
    debugPrint('FATAL: ${details.exception}');
    return Material(
      child: Container(
        color: const Color(0xFF0A2A44),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.white54, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please restart the app or contact support.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  ThemeMode initialTheme = ThemeMode.system;
  try {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('theme_mode');
    initialTheme = saved == 'dark'
        ? ThemeMode.dark
        : saved == 'light'
            ? ThemeMode.light
            : ThemeMode.system;
  } catch (e, st) {
    debugPrint('Theme preference init failed: $e');
    await Sentry.captureException(e, stackTrace: st);
  }

  try {
    await Hive.initFlutter();
    await HiveStore.openBox(HiveStore.defaultBoxName);
    await Hive.openBox<String>('post_drafts');
    await HiveService.initialize();
  } catch (e, st) {
    debugPrint('Hive init failed, falling back to in-memory cache: $e');
    await Sentry.captureException(e, stackTrace: st);
  }

  runApp(ProviderScope(overrides: [
    themeModeProvider.overrideWith((ref) => initialTheme),
  ], child: const StudyApp()));

  unawaited(_initializePostLaunchServices());
}

Future<void> _initializePostLaunchServices() async {
  try {
    await AnalyticsService.initialize();
  } catch (e, st) {
    debugPrint('AnalyticsService init failed: $e');
    await Sentry.captureException(e, stackTrace: st);
  }

  try {
    await NotificationService.initialize();
  } catch (e, st) {
    debugPrint('NotificationService init failed: $e');
    await Sentry.captureException(e, stackTrace: st);
  }

  try {
    await RetentionService().markAppOpened();
    await RetentionService().refreshStudyReminder();
  } catch (e, st) {
    debugPrint('RetentionService init failed: $e');
    await Sentry.captureException(e, stackTrace: st);
  }

  // Retry pending submissions (Issues 2 & 3)
  ConnectivityService.onConnectivityChanged.listen((_) async {
    if (await ConnectivityService.isConnected()) {
      try {
        final client = buildGraphQLClient();
        await HiveService.retryPendingQuizSubmissions(client);
        await HiveService.retryPendingScans();
      } catch (e, st) {
        debugPrint('Pending submission retry failed: $e');
        await Sentry.captureException(e, stackTrace: st);
      }
    }
  });

  // Also retry on first launch after a brief delay
  Future.delayed(const Duration(seconds: 3), () async {
    if (await ConnectivityService.isConnected()) {
      try {
        final client = buildGraphQLClient();
        await HiveService.retryPendingQuizSubmissions(client);
        await HiveService.retryPendingScans();
      } catch (e, st) {
        debugPrint('Initial pending submission retry failed: $e');
        await Sentry.captureException(e, stackTrace: st);
      }
    }
  });
}

// StudyApp has been moved to lib/app.dart for modularity.
import 'app.dart';
