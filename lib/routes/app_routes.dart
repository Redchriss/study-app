import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/kids_mode/presentation/screens/kids_home_screen.dart';
import '../../features/kids_mode/presentation/screens/kids_journey_screen.dart';
import '../../features/kids_mode/presentation/screens/kid_login_screen.dart';
import '../../features/kids_mode/presentation/screens/parent_kids_progress_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/profile/presentation/screens/about_screen.dart';
import '../../features/profile/presentation/screens/legal_content.dart';
import '../../features/profile/presentation/screens/site_page_screen.dart';
import '../../features/account/presentation/screens/upgrade_screen.dart';
import '../../features/account/presentation/screens/history_screen.dart';
import '../../features/account/presentation/screens/bookmarks_screen.dart';
import '../../features/account/presentation/screens/past_papers_screen.dart';
import '../../features/account/presentation/screens/edit_profile_screen.dart';
import '../../features/account/presentation/screens/upload_material_screen.dart';
import '../../features/account/presentation/screens/past_paper_library_screen.dart';
import '../../features/account/presentation/screens/past_paper_detail_screen.dart';
import '../../features/account/presentation/screens/quiz_share_screen.dart';
import '../../features/scanner/presentation/screens/scanner_screen.dart';
import '../../features/scanner/presentation/screens/scanner_results_screen.dart';
import '../../features/quizzes/presentation/screens/quizzes_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_take_screen.dart';
import '../../features/quizzes/presentation/screens/quiz_results_screen.dart';
import '../../features/materials/presentation/screens/my_uploads_screen.dart';

List<GoRoute> get appRoutes => [
  // Kids Mode
  GoRoute(path: '/kids', builder: (_, __) => const KidLoginScreen()),
  GoRoute(path: '/kids/learn', builder: (_, __) => const KidsHomeScreen()),
  GoRoute(
    path: '/kids/journey',
    builder: (_, state) {
      final extra = state.extra;
      final data = extra is Map
          ? Map<String, dynamic>.from(extra)
          : const <String, dynamic>{};
      return KidsJourneyScreen(
        subjectId: data['subjectId']?.toString() ?? '',
        subjectName: data['subjectName']?.toString() ?? 'Journey',
        standard: (data['standard'] as num?)?.toInt() ?? 1,
      );
    },
  ),
  GoRoute(
      path: '/kids/progress',
      builder: (_, __) => const ParentKidsProgressScreen()),

  // Scanner & Quiz
  GoRoute(path: '/scanner', builder: (_, __) => const ScannerScreen()),
  GoRoute(
    path: '/scanner/results',
    builder: (_, state) => ScannerResultsScreen(
      sessionData: (state.extra is Map)
          ? Map<String, dynamic>.from(state.extra as Map)
          : {},
    ),
  ),
  GoRoute(
    path: '/quiz/:slug',
    builder: (_, state) =>
        QuizTakeScreen(slug: state.pathParameters['slug']!),
  ),
  GoRoute(
    path: '/quiz-results/:attemptId',
    builder: (_, state) =>
        QuizResultsScreen(attemptId: state.pathParameters['attemptId']!),
  ),
  GoRoute(
    path: '/quizzes',
    builder: (_, __) => const QuizzesScreen(),
    routes: [
      GoRoute(
          path: ':slug/share',
          builder: (_, state) =>
              QuizShareScreen(quizSlug: state.pathParameters['slug']!)),
    ],
  ),
  GoRoute(
      path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),

  // Account
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

  // Legal / About
  GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
  GoRoute(
    path: '/legal/terms',
    builder: (_, __) => const SitePageScreen(
      slug: 'terms', fallbackTitle: 'Terms of Service', fallbackContent: kTermsFallback,
    ),
  ),
  GoRoute(
    path: '/legal/privacy',
    builder: (_, __) => const SitePageScreen(
      slug: 'privacy', fallbackTitle: 'Privacy Policy', fallbackContent: kPrivacyFallback,
    ),
  ),
  GoRoute(
    path: '/legal/faq',
    builder: (_, __) => const SitePageScreen(
      slug: 'faq', fallbackTitle: 'FAQ', fallbackContent: kFaqFallback,
    ),
  ),
  GoRoute(
    path: '/legal/support',
    builder: (_, __) => const SitePageScreen(
      slug: 'support', fallbackTitle: 'Support & Contact', fallbackContent: kSupportFallback,
    ),
  ),
];
