import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_hero.dart';
import 'profile_posts_tab.dart';
import 'profile_comments_tab.dart';
import 'profile_saved_tab.dart';

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
                  child: _AchievementsRow(achievements: achievements),
                ),
              SliverToBoxAdapter(
                child: _ProfileActions(isOwnProfile: true, username: username),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarDelegate(
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

class _AchievementsRow extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const _AchievementsRow({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: achievements.map((a) {
          final ach = a['achievement'] as Map<String, dynamic>?;
          final name = ach?['name']?.toString() ?? '';
          final iconUrl = ach?['iconUrl']?.toString() ?? '';
          final category = ach?['category']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: iconUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(iconUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  _achIcon(category),
                                  color: DesignTokens.primary,
                                  size: 22)),
                        )
                      : Icon(_achIcon(category),
                          color: DesignTokens.primary, size: 22),
                ),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _achIcon(String cat) {
    switch (cat) {
      case 'community':
        return Icons.groups_rounded;
      case 'content':
        return Icons.article_rounded;
      case 'engagement':
        return Icons.chat_rounded;
      case 'milestone':
        return Icons.emoji_events_rounded;
      default:
        return Icons.auto_awesome_rounded;
    }
  }
}

class _ProfileActions extends ConsumerWidget {
  final bool isOwnProfile;
  final String username;

  const _ProfileActions({required this.isOwnProfile, required this.username});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          FilledButton.icon(
            onPressed: () => context.push('/edit-profile'),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Profile'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined, size: 16),
            label: const Text('Settings'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: dark ? DesignTokens.darkBackground : DesignTokens.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => false;
}
