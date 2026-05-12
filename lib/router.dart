import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/onboarding_screen.dart';
import '../features/auth/presentation/screens/profile_setup_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/materials/presentation/screens/materials_screen.dart';
import '../features/materials/presentation/screens/material_detail_screen.dart';
import '../features/quizzes/presentation/screens/quizzes_screen.dart';
import '../features/quizzes/presentation/screens/quiz_take_screen.dart';
import '../features/quizzes/presentation/screens/quiz_results_screen.dart';
import '../features/ai_tutor/presentation/screens/ai_tutor_screen.dart';
import '../features/scanner/presentation/screens/scanner_screen.dart';
import '../features/scanner/presentation/screens/scanner_results_screen.dart';
import '../features/circles/presentation/screens/circles_screen.dart';
import '../features/circles/presentation/screens/circle_detail_screen.dart';
import '../features/circles/presentation/screens/post_detail_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../features/account/presentation/screens/upgrade_screen.dart';
import '../features/account/presentation/screens/history_screen.dart';
import '../features/account/presentation/screens/bookmarks_screen.dart';
import '../features/account/presentation/screens/past_papers_screen.dart';
import '../features/kids_mode/presentation/screens/kids_home_screen.dart';
import '../features/kids_mode/presentation/screens/kid_login_screen.dart';
import '../features/profile/presentation/screens/about_screen.dart';
import 'shell.dart';

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

      if (auth.isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      if (!auth.isAuthenticated) {
        if (['/login', '/register', '/onboarding'].contains(location)) {
          return null;
        }
        if (location == '/splash') return '/onboarding';
        return '/onboarding';
      }

      final profileComplete = auth.user?['profile']?['onboardingComplete'] == true;
      if (!profileComplete && location != '/setup') return '/setup';

      if (profileComplete && ['/login', '/register', '/onboarding'].contains(location)) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/setup', builder: (_, __) => const ProfileSetupScreen()),

      // Kids Mode (separate shell)
      GoRoute(path: '/kids', builder: (_, __) => const KidLoginScreen()),
      GoRoute(path: '/kids/learn', builder: (_, __) => const KidsHomeScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(
            path: '/materials',
            builder: (_, __) => const MaterialsScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (_, state) => MaterialDetailScreen(slug: state.pathParameters['slug']!),
              ),
            ],
          ),
          GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
          GoRoute(path: '/circles', builder: (_, __) => const CirclesScreen(),
            routes: [
              GoRoute(
                path: ':slug',
                builder: (_, state) => CircleDetailScreen(slug: state.pathParameters['slug']!),
                routes: [
                  GoRoute(
                    path: 'post/:postSlug',
                    builder: (_, state) => PostDetailScreen(
                      circleSlug: state.pathParameters['slug']!,
                      postSlug: state.pathParameters['postSlug']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Full-screen routes (no bottom nav)
      GoRoute(
        path: '/quiz/:slug',
        builder: (_, state) => QuizTakeScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/quiz-results/:attemptId',
        builder: (_, state) => QuizResultsScreen(attemptId: state.pathParameters['attemptId']!),
      ),
      GoRoute(
        path: '/scanner/results',
        builder: (_, state) => ScannerResultsScreen(
          sessionData: (state.extra is Map) ? Map<String, dynamic>.from(state.extra as Map) : {},
        ),
      ),
      GoRoute(path: '/ai-tutor', builder: (_, __) => const AiTutorScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/upgrade', builder: (_, __) => const UpgradeScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/bookmarks', builder: (_, __) => const BookmarksScreen()),
      GoRoute(path: '/past-papers', builder: (_, __) => const PastPapersScreen()),
      GoRoute(
        path: '/quizzes',
        builder: (_, __) => const QuizzesScreen(),
      ),
    ],
  );
});
