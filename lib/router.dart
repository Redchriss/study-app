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
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/materials/presentation/screens/materials_screen.dart';
import '../features/materials/presentation/screens/material_detail_screen.dart';
import '../features/materials/presentation/screens/material_reader_screen.dart';
import '../features/materials/presentation/screens/my_uploads_screen.dart';
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
import '../features/account/presentation/screens/edit_profile_screen.dart';
import '../features/account/presentation/screens/upload_material_screen.dart';
import '../features/account/presentation/screens/past_paper_library_screen.dart';
import '../features/account/presentation/screens/past_paper_detail_screen.dart';
import '../features/account/presentation/screens/quiz_share_screen.dart';
import '../features/kids_mode/presentation/screens/kids_home_screen.dart';
import '../features/kids_mode/presentation/screens/kids_journey_screen.dart';
import '../features/kids_mode/presentation/screens/kid_login_screen.dart';
import '../features/kids_mode/presentation/screens/parent_kids_progress_screen.dart';
import '../features/profile/presentation/screens/about_screen.dart';
import '../features/profile/presentation/screens/site_page_screen.dart';
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
      final isKidsRoute = location == '/kids' || location.startsWith('/kids/');

      if (auth.isLoading) {
        return location == '/splash' || isKidsRoute ? null : '/splash';
      }

      if (!auth.isAuthenticated) {
        if (['/login', '/register', '/onboarding'].contains(location) || isKidsRoute) {
          return null;
        }
        if (location == '/splash') return '/onboarding';
        return '/onboarding';
      }

      final profileComplete = auth.user?['profile']?['onboardingComplete'] == true;
      if (location == '/splash') {
        return profileComplete ? '/home' : '/setup';
      }
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
      GoRoute(
        path: '/kids/journey',
        builder: (_, state) {
          final extra = state.extra;
          final data = extra is Map ? Map<String, dynamic>.from(extra) : const <String, dynamic>{};
          return KidsJourneyScreen(
            subjectId: data['subjectId']?.toString() ?? '',
            subjectName: data['subjectName']?.toString() ?? 'Journey',
            standard: (data['standard'] as num?)?.toInt() ?? 1,
          );
        },
      ),
      GoRoute(path: '/kids/progress', builder: (_, __) => const ParentKidsProgressScreen()),

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
                routes: [
                  GoRoute(
                    path: 'read',
                    builder: (_, state) => MaterialReaderScreen(slug: state.pathParameters['slug']!),
                  ),
                ],
              ),
            ],
          ),
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
      GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
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
      GoRoute(
        path: '/legal/terms',
        builder: (_, __) => const SitePageScreen(
          slug: 'terms',
          fallbackTitle: 'Terms of Service',
          fallbackContent: _kTermsFallback,
        ),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (_, __) => const SitePageScreen(
          slug: 'privacy',
          fallbackTitle: 'Privacy Policy',
          fallbackContent: _kPrivacyFallback,
        ),
      ),
      GoRoute(
        path: '/legal/faq',
        builder: (_, __) => const SitePageScreen(
          slug: 'faq',
          fallbackTitle: 'FAQ',
          fallbackContent: _kFaqFallback,
        ),
      ),
      GoRoute(
        path: '/legal/support',
        builder: (_, __) => const SitePageScreen(
          slug: 'support',
          fallbackTitle: 'Support & Contact',
          fallbackContent: _kSupportFallback,
        ),
      ),
      GoRoute(path: '/upgrade', builder: (_, __) => const UpgradeScreen()),
      GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/bookmarks', builder: (_, __) => const BookmarksScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/past-papers', builder: (_, __) => const PastPapersScreen()),
      GoRoute(path: '/paper-library', builder: (_, __) => const PastPaperLibraryScreen()),
      GoRoute(
        path: '/past-paper/view',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map) {
            return Scaffold(
              appBar: AppBar(title: const Text('Past paper')),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('Pick a paper from the library again.'),
                ),
              ),
            );
          }
          return PastPaperDetailScreen(paper: Map<String, dynamic>.from(extra));
        },
      ),
      GoRoute(path: '/upload-material', builder: (_, __) => const UploadMaterialScreen()),
      GoRoute(path: '/my-uploads', builder: (_, __) => const MyUploadsScreen()),
      GoRoute(
        path: '/quizzes',
        builder: (_, __) => const QuizzesScreen(),
        routes: [
          GoRoute(path: ':slug/share', builder: (_, state) => QuizShareScreen(quizSlug: state.pathParameters['slug']!)),
        ],
      ),
    ],
  );
});

// ── Fallback legal content (shown when backend returns nothing yet) ─────────────
const _kTermsFallback = '''
# Terms of Service

**Effective date: January 1, 2025**

By using Yaza you agree to these terms. Please read them carefully.

## 1. Use of the App
Yaza is an AI-powered study companion for Malawian students. You must be at least 6 years old to use the app.

## 2. User Content
You own content you upload. By uploading materials, you grant Yaza a licence to use them to improve the service.

## 3. AI-Generated Content
AI responses are for study assistance only. Always verify important information with your teacher or textbook.

## 4. Privacy
We respect your privacy. See our Privacy Policy for details on how we handle your data.

## 5. Changes
We may update these terms. Continued use after changes means you accept them.

**Contact:** support@yaza.app
''';

const _kPrivacyFallback = '''
# Privacy Policy

**Effective date: January 1, 2025**

Your privacy matters to us. This policy explains what we collect and why.

## What We Collect
- **Account info:** name, email, education level
- **Usage data:** subjects studied, quiz scores, session length
- **Kids Mode:** child name and education track (no email required for kids)

## How We Use It
- Personalise your study experience
- Improve AI recommendations
- Keep your account secure

## What We Don't Do
- We do not sell your data to third parties
- We do not show ads based on your personal data
- We do not share data with schools without your consent

## Data Storage
Data is stored securely on Render (US) servers with encryption at rest.

## Your Rights
You can request deletion of your account and all data at any time via support@yaza.app.

## Children
Kids Mode collects minimal data. No email or real name is required for child profiles.

**Contact:** support@yaza.app
''';

const _kFaqFallback = '''
# Frequently Asked Questions

## Is Yaza free?
Yaza has a free tier with generous limits. Premium plans unlock unlimited AI tutor sessions and advanced features.

## What subjects does Yaza cover?
All MSCE subjects including English, Chichewa, Mathematics, Biology, Physics, Chemistry, History, Geography, and more.

## Does Yaza work offline?
Some features require internet. Cached lessons can be read offline.

## Is Kids Mode safe?
Yes. Kids Mode uses a separate PIN-protected login and collects no email or sensitive data.

## How accurate is the AI tutor?
Our AI is trained on the Malawian curriculum. Always double-check critical answers with your textbook or teacher.

## How do I upload my own materials?
Go to Materials → tap the + button → upload a PDF or image.

## Can I use Yaza on multiple devices?
Yes — your account syncs across all devices.

## How do I delete my account?
Go to Profile → Settings → Delete Account, or email support@yaza.app.
''';

const _kSupportFallback = '''
# Support & Contact

We are here to help. Reach us through any of the channels below.

## Email
**support@yaza.app** — we respond within 24 hours.

## Reporting a Bug
Describe what happened, your device model, and app version. Send to support@yaza.app.

## Feature Requests
We love hearing from students and teachers. Email us your ideas!

## Social
Follow us on Twitter/X: **@YazaApp**
''';

