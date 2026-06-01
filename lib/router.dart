import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/ai_tutor/presentation/screens/ai_tutor_screen.dart';
import '../features/circles/presentation/screens/home_screen.dart';
import '../features/circles/presentation/screens/discover_screen.dart';
import '../features/circles/presentation/screens/inbox_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/presentation/screens/modmail_thread_list.dart';
import '../features/notifications/presentation/screens/modmail_thread_detail.dart';
import '../features/notifications/presentation/screens/send_modmail_screen.dart';
import '../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../core/services/analytics_service.dart';
import 'shell.dart';
import 'routes/community_routes.dart';
import 'routes/app_routes.dart';

/// Logs screen views to analytics on every navigation.
class _AnalyticsObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    final name = route.settings.name ?? route.settings.toString();
    AnalyticsService.logScreenView(name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      final name = newRoute.settings.name ?? newRoute.settings.toString();
      AnalyticsService.logScreenView(name);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      final name =
          previousRoute.settings.name ?? previousRoute.settings.toString();
      AnalyticsService.logScreenView(name);
    }
  }
}

class _RouterRefresh extends ChangeNotifier {
  late final ProviderSubscription _sub;
  _RouterRefresh(Ref ref) {
    _sub = ref.listen(authProvider, (_, __) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

final _analyticsObserver = _AnalyticsObserver();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    observers: [_analyticsObserver],
    refreshListenable: _RouterRefresh(ref),
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final isKidsRoute = location == '/kids' || location.startsWith('/kids/');

      if (auth.isLoading || auth.biometricRequired) {
        return location == '/splash' || isKidsRoute ? null : '/splash';
      }

      if (!auth.isAuthenticated) {
        if (['/login', '/register', '/onboarding'].contains(location) ||
            isKidsRoute) {
          return null;
        }
        if (location == '/splash') return '/onboarding';
        return '/onboarding';
      }

      final profileComplete =
          auth.user?['profile']?['onboardingComplete'] == true;
      if (location == '/splash') {
        return profileComplete ? '/home' : '/setup';
      }
      if (!profileComplete && location != '/setup') return '/setup';

      if (profileComplete &&
          ['/login', '/register', '/onboarding'].contains(location)) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const ProfileSetupScreen()),

      // Standalone AI Tutor route (keep accessible from quick actions)
      GoRoute(path: '/ai-tutor', builder: (_, __) => const AiTutorScreen()),

      ...appRoutes,

      // Main shell with bottom nav: Home | Discover | Inbox | Profile
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (_, __) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/discover',
                  builder: (_, __) => const DiscoverScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                  path: '/profile', builder: (_, __) => const ProfileScreen()),
            ],
          ),
        ],
      ),

      // Notification & modmail routes (outside shell)
      GoRoute(
        path: '/modmail-list/:communitySlug',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          return ModmailThreadList(
            communitySlug: state.pathParameters['communitySlug']!,
            communityName: extra['communityName'] as String? ??
                state.pathParameters['communitySlug']!,
          );
        },
      ),
      GoRoute(
        path: '/modmail/:threadId',
        builder: (context, state) {
          final extra = state.extra as Map? ?? {};
          return ModmailThreadDetail(
            threadId: state.pathParameters['threadId']!,
            communitySlug: extra['communitySlug'] as String? ?? '',
            communityName: extra['communityName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/send-modmail',
        builder: (_, __) => const SendModmailScreen(),
      ),
      GoRoute(
        path: '/notification-preferences',
        builder: (_, __) => const NotificationPreferencesScreen(),
      ),

      ...communityRoutes,
    ],
  );
});
