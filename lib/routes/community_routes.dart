import 'package:go_router/go_router.dart';
import '../../features/circles/presentation/screens/community_screen.dart';
import '../../features/circles/presentation/screens/post_detail_screen.dart';
import '../../features/circles/presentation/screens/create_post_screen.dart';
import '../../features/circles/presentation/screens/discover_screen.dart';
import '../../features/circles/presentation/screens/create_community_screen.dart';
import '../../features/circles/presentation/screens/search_screen.dart';
import '../../features/circles/presentation/screens/mod_panel_screen.dart';
import '../../features/circles/presentation/screens/user_profile_screen.dart';
import '../../features/circles/presentation/screens/inbox_screen.dart';
import '../../features/circles/presentation/screens/community_sidebar_screen.dart';

List<GoRoute> get communityRoutes => [
      GoRoute(
        path: '/y/:slug',
        builder: (_, state) =>
            CommunityScreen(slug: state.pathParameters['slug']!),
        routes: [
          GoRoute(
            path: 'post/:postSlug',
            builder: (_, state) => PostDetailScreen(
              communitySlug: state.pathParameters['slug']!,
              postSlug: state.pathParameters['postSlug']!,
              commentId: state.uri.queryParameters['commentId'],
            ),
          ),
          GoRoute(
            path: 'submit',
            builder: (_, state) =>
                CreatePostScreen(communitySlug: state.pathParameters['slug']!),
          ),
          GoRoute(
            path: 'mod',
            builder: (_, state) =>
                ModPanelScreen(communitySlug: state.pathParameters['slug']!),
          ),
          GoRoute(
            path: 'wiki',
            builder: (_, state) => CommunitySidebarScreen(
              slug: state.pathParameters['slug']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/u/:username',
        builder: (_, state) =>
            UserProfileScreen(username: state.pathParameters['username']!),
      ),
      GoRoute(path: '/inbox', builder: (_, __) => const InboxScreen()),
      GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
      GoRoute(
        path: '/search',
        builder: (_, state) =>
            SearchScreen(initialQuery: state.uri.queryParameters['q']),
      ),
      GoRoute(
          path: '/create-community',
          builder: (_, __) => const CreateCommunityScreen()),
    ];
