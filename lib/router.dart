import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/ai_tutor/presentation/screens/ai_tutor_screen.dart';
import '../features/circles/presentation/screens/home_screen.dart';
import '../features/circles/presentation/screens/discover_screen.dart';
import '../features/circles/presentation/screens/inbox_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import 'shell.dart';
import 'routes/community_routes.dart';
import 'routes/app_routes.dart';

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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    refreshListenable: _RouterRefresh(ref),
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final location = state.matchedLocation;
      final isKidsRoute = location == '/kids' || location.startsWith('/kids/');

      if (auth.isLoading) {
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

      // Standalone AI Tutor route (keep accessible from Dashboard quick actions)
      GoRoute(path: '/ai-tutor', builder: (_, __) => const AiTutorScreen()),

      // Standalone Circles community feed (keep accessible from Dashboard)
      GoRoute(path: '/circles', builder: (_, __) => const HomeScreen()),

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

      ...communityRoutes,
    ],
  );
});
