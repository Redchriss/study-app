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
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/notifications/presentation/screens/modmail_thread_list.dart';
import '../features/notifications/presentation/screens/modmail_thread_detail.dart';
import '../features/notifications/presentation/screens/send_modmail_screen.dart';
import '../features/notifications/presentation/screens/notification_preferences_screen.dart';
import '../core/services/analytics_service.dart';
import 'shell.dart';
import 'routes/community_routes.dart';
import 'routes/app_routes.dart';
import 'study_hub_screen.dart';

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
      AnalyticsService.logScreenView(
          newRoute.settings.name ?? newRoute.settings.toString());
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      AnalyticsService.logScreenView(
          previousRoute.settings.name ?? previousRoute.settings.toString());
    }
  }
}

final _analyticsObserver = _AnalyticsObserver();

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    observers: [_analyticsObserver],
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isKidsRoute = location == '/kids' || location.startsWith('/kids/');

      if (auth.isLoading || auth.isSubmitting || auth.biometricRequired) {
        return location == '/splash' || isKidsRoute ? null : '/splash';
      }

      if (!auth.isAuthenticated) {
        const authRoutes = ['/login', '/register', '/splash'];
        if (authRoutes.contains(location) || isKidsRoute) return null;
        return '/login';
      }

      final profileComplete =
          auth.user?['profile']?['onboardingComplete'] == true;

      if (location == '/splash') {
        return profileComplete ? '/home' : '/setup';
      }

      if (!profileComplete && location != '/setup') {
        const authRoutes = ['/login', '/register'];
        if (authRoutes.contains(location)) return null;
        return '/setup';
      }

      if (profileComplete &&
          ['/login', '/register'].contains(location)) {
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

      // AI Tutor — full screen, no shell (pushed from anywhere)
      GoRoute(path: '/ai-tutor', builder: (_, __) => const AiTutorScreen()),

      ...appRoutes,

      // ── Shell: 4 tabs ──────────────────────────────────────────
      // Tab 0: Home (Dashboard)
      // Tab 1: Study hub (Materials + Quizzes + Scanner)
      // Tab 2: Circles (community feed + discover + inbox)
      // Tab 3: Profile
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // ── Tab 0: Dashboard ──────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const DashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'notifications',
                    builder: (_, __) => const NotificationsScreen(),
                  ),
                ],
              ),
            ],
          ),
          // ── Tab 1: Study hub ──────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (_, __) => const StudyHubScreen(),
              ),
            ],
          ),
          // ── Tab 2: Circles ───────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/circles',
                builder: (_, __) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'discover',
                    builder: (_, __) => const DiscoverScreen(),
                  ),
                  GoRoute(
                    path: 'inbox',
                    builder: (_, __) => const InboxScreen(),
                  ),
                ],
              ),
            ],
          ),
          // ── Tab 3: Profile ───────────────────────────────────
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
