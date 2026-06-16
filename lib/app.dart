import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/design_tokens.dart';
import 'core/services/analytics_service.dart';
import 'core/widgets/offline_banner.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'main.dart' show themeModeProvider;
import 'router.dart';

/// The root of the Yaza application.
/// 
/// This file separates the material app configuration from the
/// post-launch services and initialization logic in main.dart.
class StudyApp extends ConsumerWidget {
  const StudyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final client = ref.watch(graphqlClientProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Context-aware listener for route changes (Log screen views)
    ref.listen(routerProvider, (_, GoRouter next) {
      final uri = next.routeInformationProvider.value.uri.toString();
      AnalyticsService.logScreenView(uri);
    });

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
          // OfflineBanner wraps the entire app to show connectivity banners
          return OfflineBanner(child: child ?? const SizedBox.shrink());
        },
      ),
    );
  }
}
