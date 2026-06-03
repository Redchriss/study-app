import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_hero.dart';
import 'profile_posts_tab.dart';
import 'profile_comments_tab.dart';
import 'profile_saved_tab.dart';
import 'profile_achievements_row.dart';
import 'profile_actions.dart';
import 'profile_tab_bar_delegate.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kProfile),
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return Scaffold(
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: const [
                SizedBox(height: 120),
                ShimmerBox(height: 200, radius: DesignTokens.radiusXl),
                SizedBox(height: 16),
                ShimmerBox(height: 300, radius: DesignTokens.radiusXl),
              ],
            ),
          );
        }

        if (result.hasException && result.data?['me'] == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Profile',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              centerTitle: true,
            ),
            body: ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load profile.'),
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final me = result.data?['me'] as Map<String, dynamic>?;
        final profile = me?['profile'] as Map<String, dynamic>?;
        final username = me?['username'] as String? ?? 'User';
        final avatarUrl = profile?['avatarUrl']?.toString();
        final bannerUrl = profile?['bannerUrl']?.toString();
        final bio = profile?['bio']?.toString();
        final postKarma = (profile?['postKarma'] as num?)?.toInt() ?? 0;
        final commentKarma = (profile?['commentKarma'] as num?)?.toInt() ?? 0;
        final awardKarma = (profile?['awardKarma'] as num?)?.toInt() ?? 0;
        final totalKarma = postKarma + commentKarma + awardKarma;
        final createdAt = profile?['createdAt']?.toString();
        final followers =
            (result.data?['myFollowersCount'] as num?)?.toInt() ?? 0;
        final following =
            (result.data?['myFollowingCount'] as num?)?.toInt() ?? 0;
        final achievements =
            (me?['achievements'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              ProfileHeader(
                avatarUrl: avatarUrl,
                bannerUrl: bannerUrl,
                username: username,
                bio: bio,
                postKarma: postKarma,
                commentKarma: commentKarma,
                awardKarma: awardKarma,
                totalKarma: totalKarma,
                createdAt: createdAt,
                isOwnProfile: true,
                followers: followers,
                following: following,
              ),
              if (achievements.isNotEmpty)
                SliverToBoxAdapter(
                  child: ProfileAchievementsRow(achievements: achievements),
                ),
              SliverToBoxAdapter(
                child: ProfileActions(isOwnProfile: true, username: username),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: ProfileTabBarDelegate(
                  TabBar(
                    controller: _tabCtrl,
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Comments'),
                      Tab(text: 'Saved'),
                    ],
                    labelColor: DesignTokens.primary,
                    unselectedLabelColor: DesignTokens.textSecondary,
                    indicatorSize: TabBarIndicatorSize.label,
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabCtrl,
              children: [
                ProfilePostsTab(username: username),
                ProfileCommentsTab(username: username),
                const ProfileSavedTab(),
              ],
            ),
          ),
        );
      },
    );
  }
}
