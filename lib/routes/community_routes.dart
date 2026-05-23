import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/circles/presentation/screens/community_screen.dart';
import '../../features/circles/presentation/screens/post_detail_screen.dart';
import '../../features/circles/presentation/screens/create_post_screen.dart';
import '../../features/circles/presentation/screens/discover_screen.dart';
import '../../features/circles/presentation/screens/create_community_screen.dart';
import '../../features/circles/presentation/screens/search_screen.dart';
import '../../features/circles/presentation/screens/mod_panel_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

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
        ),
      ),
      GoRoute(
        path: 'submit',
        builder: (_, state) => CreatePostScreen(
            communitySlug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: 'mod',
        builder: (_, state) => ModPanelScreen(
            communitySlug: state.pathParameters['slug']!),
      ),
    ],
  ),
  GoRoute(path: '/inbox', builder: (_, __) => const NotificationsScreen()),
  GoRoute(path: '/discover', builder: (_, __) => const DiscoverScreen()),
  GoRoute(
    path: '/search',
    builder: (_, state) => SearchScreen(
        initialQuery: state.uri.queryParameters['q']),
  ),
  GoRoute(
      path: '/create-community',
      builder: (_, __) => const CreateCommunityScreen()),
];
