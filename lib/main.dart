import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';
import 'core/config/app_config.dart';
import 'core/services/analytics_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/retention_service.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'router.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry if DSN is configured
  if (AppConfig.sentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = AppConfig.sentryDsn;
        options.environment = AppConfig.sentryEnvironment;
        options.tracesSampleRate = 1.0;
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

  // Initialize environment configuration
  await AppConfig.init();

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
}

class StudyApp extends ConsumerWidget {
  const StudyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final client = ref.watch(graphqlClientProvider);
    final themeMode = ref.watch(themeModeProvider);
    return GraphQLProvider(
      client: ValueNotifier(client),
      child: MaterialApp.router(
        title: 'Yaza',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          // Router can pass null child briefly; SizedBox.shrink() looks like a "frozen" blank screen.
          final routed = child ??
              const Scaffold(
                backgroundColor: DesignTokens.primary,
                body: Center(child: CircularProgressIndicator(color: Colors.white)),
              );
          return OfflineBanner(child: routed);
        },
      ),
    );
  }
}
