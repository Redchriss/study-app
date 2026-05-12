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
import '../features/kids_mode/presentation/screens/kids_home_screen.dart';
import '../features/kids_mode/presentation/screens/kid_login_screen.dart';
import 'shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authAsync = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final auth = authAsync.valueOrNull;
      if (auth == null || auth.isLoading) return null;

      final isAuth = auth.isAuthenticated;
      final location = state.matchedLocation;
      final isOnAuth = location.startsWith('/login') ||
          location.startsWith('/register') ||
          location.startsWith('/onboarding') ||
          location.startsWith('/setup') ||
          location == '/splash';

      if (!isAuth && !isOnAuth) return '/login';
      if (!isAuth) return null;

      final profileComplete = auth.user?['profile']?['onboardingComplete'] == true;
      if (isAuth && !profileComplete && location != '/setup') return '/setup';
      if (isAuth && profileComplete && isOnAuth && location != '/splash') return '/home';
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
          sessionData: state.extra as Map<String, dynamic>? ?? {},
        ),
      ),
      GoRoute(path: '/ai-tutor', builder: (_, __) => const AiTutorScreen()),
      GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
      GoRoute(
        path: '/quizzes',
        builder: (_, __) => const QuizzesScreen(),
      ),
    ],
  );
});
