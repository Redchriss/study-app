import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/onboarding_v2/onboarding_screen_v2.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/agent/presentation/screens/agent_screen.dart';
import '../features/diagnostics/presentation/screens/diagnostic_screen.dart';
import '../features/diagnostics/presentation/screens/knowledge_map_screen.dart';
import '../features/diagnostics/presentation/screens/prerequisite_graph_screen.dart';
import '../features/tools/presentation/screens/tools_screen.dart';
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
import 'features/study_hub/presentation/screens/study_hub_screen.dart';

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
  final router = GoRouter(
    observers: [_analyticsObserver],
    initialLocation: '/splash',
    refreshListenable: _AuthStateNotifier(ref),
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final isKidsRoute = location == '/kids' || location.startsWith('/kids/');

      if (auth.isSubmitting)
        return null; // stay on current screen during login/register

      if (auth.isLoading || auth.biometricRequired) {
        return location == '/splash' || isKidsRoute ? null : '/splash';
      }

      if (!auth.isAuthenticated) {
        const authRoutes = ['/login', '/register', '/onboarding'];
        if (location == '/splash') return '/onboarding';
        if (authRoutes.contains(location) || isKidsRoute) return null;
        return '/login';
      }

      final profileComplete =
          auth.user?['profile']?['onboardingComplete'] == true;

      if (location == '/splash') {
        return profileComplete ? '/home' : '/setup';
      }

      if (!profileComplete && location != '/setup') {
        return '/setup';
      }

      if (profileComplete && ['/login', '/register'].contains(location)) {
        return '/home';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(
          path: '/onboarding', builder: (_, __) => const OnboardingScreenV2()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const ProfileSetupScreen()),

      // Agent — full screen, no shell (pushed from anywhere)
      GoRoute(
        path: '/ai-tutor',
        builder: (_, state) => AgentScreen(
          initialPrompt: state.extra is Map
              ? (state.extra as Map)['prompt'] as String?
              : null,
        ),
      ),

      // Diagnostic & Knowledge Map (AI 2.0)
      GoRoute(
        path: '/diagnostic/:subjectCode',
        builder: (_, state) => DiagnosticScreen(
          subjectCode: state.pathParameters['subjectCode'] ?? 'MATH-S',
        ),
      ),
      GoRoute(
        path: '/knowledge-map',
        builder: (_, state) {
          final extra = state.extra as Map? ?? {};
          return KnowledgeMapScreen(
            subjectCode: (extra['subjectCode'] as String?) ?? 'MATH-S',
          );
        },
      ),
      GoRoute(
        path: '/prerequisite-graph/:subjectCode',
        builder: (_, state) => PrerequisiteGraphScreen(
          subjectCode: state.pathParameters['subjectCode'] ?? 'MATH-S',
        ),
      ),

      // Tools hub — all AI and study tools in one place
      GoRoute(
        path: '/tools',
        builder: (_, __) => const ToolsScreen(),
      ),

      ...appRoutes,

      // ── Shell: 4 tabs ──────────────────────────────────────────
      // Tab 0: Feed (social — first thing you see)
      // Tab 1: Study hub (Materials + Quizzes + Scanner)
      // Tab 2: Dashboard (stats + agent)
      // Tab 3: Profile
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // ── Tab 0: Feed ───────────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
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
          // ── Tab 1: Study hub ──────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/study',
                builder: (_, __) => const StudyHubScreen(),
              ),
            ],
          ),
          // ── Tab 2: Dashboard ─────────────────────────────────
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
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
          // ── Tab 3: Profile ────────────────────────────────────
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
  ref.onDispose(router.dispose);
  return router;
});

/// Notifies GoRouter to re-evaluate redirect when auth state changes.
/// Using refreshListenable instead of ref.watch(authProvider) prevents
/// the entire GoRouter from being recreated on every auth change.
class _AuthStateNotifier extends ChangeNotifier {
  _AuthStateNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
