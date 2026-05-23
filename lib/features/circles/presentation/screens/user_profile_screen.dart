import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'user_profile_posts_tab.dart';
import 'user_profile_comments_tab.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  final String username;
  const UserProfileScreen({super.key, required this.username});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  bool _isFollowing = false;
  bool _isBlocked = false;

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

  bool get _isOwnProfile {
    final authUser = ref.read(authProvider).user;
    return authUser?['username']?.toString() == widget.username;
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kUserProfile),
        variables: {'username': widget.username},
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: LoadingWidget()),
          );
        }
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load profile'),
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final profile = result.data?['userProfile'] as Map<String, dynamic>?;
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('User not found')),
          );
        }

        _isFollowing = profile['isFollowing'] == true;
        _isBlocked = profile['isBlocked'] == true;

        final user = profile['user'] as Map<String, dynamic>?;
        final username = user?['username']?.toString() ?? widget.username;
        final achievements =
            (profile['achievements'] as List?)?.cast<Map<String, dynamic>>() ??
                [];
        final activeCommunities = (profile['activeCommunities'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _ProfileHeader(
                profile: profile,
                username: username,
                isOwnProfile: _isOwnProfile,
                isFollowing: _isFollowing,
                isBlocked: _isBlocked,
                onFollow: _isOwnProfile ? null : _toggleFollow,
                onBlock: _isOwnProfile ? null : _toggleBlock,
              ),
              if (achievements.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: achievements.map((a) {
                        final ach = a['achievement'] as Map<String, dynamic>?;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: DesignTokens.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _achIcon(ach?['icon']?.toString()),
                                  color: DesignTokens.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ach?['name']?.toString() ?? '',
                                style: const TextStyle(fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (activeCommunities.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Active in',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: DesignTokens.textSecondary)),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 32,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: activeCommunities.map((c) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ActionChip(
                                  avatar: c['icon'] != null &&
                                          c['icon'].toString().isNotEmpty
                                      ? CircleAvatar(
                                          radius: 10,
                                          backgroundImage: NetworkImage(
                                              c['icon'].toString()),
                                        )
                                      : const CircleAvatar(
                                          radius: 10,
                                          child: Text('y',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white)),
                                        ),
                                  label: Text('y/${c['name']}',
                                      style: const TextStyle(fontSize: 11)),
                                  onPressed: () {},
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: TabBar(
                  controller: _tabCtrl,
                  tabs: [
                    const Tab(text: 'Posts'),
                    const Tab(text: 'Comments'),
                    if (_isOwnProfile) const Tab(text: 'Saved'),
                  ],
                  labelColor: DesignTokens.primary,
                  unselectedLabelColor: DesignTokens.textSecondary,
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    UserProfilePostsTab(username: widget.username),
                    UserProfileCommentsTab(username: widget.username),
                    if (_isOwnProfile) _SavedTab() else const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleFollow() async {
    final client = ref.read(graphqlClientProvider);
    final mutation = _isFollowing ? kUnfollowUser : kFollowUser;
    await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'username': widget.username},
    ));
    setState(() => _isFollowing = !_isFollowing);
  }

  Future<void> _toggleBlock() async {
    final client = ref.read(graphqlClientProvider);
    final mutation = _isBlocked ? kUnblockUser : kBlockUser;
    await client.mutate(MutationOptions(
      document: gql(mutation),
      variables: {'username': widget.username},
    ));
    setState(() => _isBlocked = !_isBlocked);
  }

  IconData _achIcon(String? icon) {
    switch (icon) {
      case 'streak':
        return Icons.local_fire_department_rounded;
      case 'posts':
        return Icons.article_rounded;
      case 'comments':
        return Icons.chat_rounded;
      case 'karma':
        return Icons.trending_up_rounded;
      case 'votes':
        return Icons.arrow_upward_rounded;
      case 'awards':
        return Icons.auto_awesome_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}

class _SavedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kSavedPosts),
        variables: const {'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (result.hasException) {
          return ErrorState(
            message:
                graphQLErrorMessage(result.exception, 'Could not load saved'),
            onRetry: () => refetch?.call(),
          );
        }
        final data = result.data?['savedPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final posts =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No saved posts',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.bookmark, size: 20),
            title: Text(posts[i]['title']?.toString() ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                'y/${(posts[i]['community'] as Map?)?['name'] ?? ''}',
                style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String username;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isBlocked;
  final VoidCallback? onFollow;
  final VoidCallback? onBlock;

  const _ProfileHeader({
    required this.profile,
    required this.username,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.isBlocked,
    this.onFollow,
    this.onBlock,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = profile['avatarUrl']?.toString();
    final bannerUrl = profile['bannerUrl']?.toString();
    final bio = profile['bio']?.toString();
    final postKarma = (profile['postKarma'] as num?)?.toInt() ?? 0;
    final commentKarma = (profile['commentKarma'] as num?)?.toInt() ?? 0;
    final awardKarma = (profile['awardKarma'] as num?)?.toInt() ?? 0;
    final totalKarma = (profile['totalKarma'] as num?)?.toInt() ?? 0;
    final createdAt = profile['createdAt']?.toString();

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            if (bannerUrl != null && bannerUrl.isNotEmpty)
              Positioned.fill(
                child: Image.network(bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                        color: DesignTokens.primary.withValues(alpha: 0.2))),
              )
            else
              Container(color: DesignTokens.primary.withValues(alpha: 0.2)),
            Positioned(
              left: 16,
              bottom: 60,
              child: CircleAvatar(
                radius: 36,
                backgroundColor: DesignTokens.surface,
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(36),
                        child: Image.network(avatarUrl,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.person,
                                size: 36, color: DesignTokens.primary)),
                      )
                    : const Icon(Icons.person, size: 36, color: DesignTokens.primary),
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(130),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('u/$username',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _KarmaChip(label: 'Post', value: postKarma),
                  const SizedBox(width: 8),
                  _KarmaChip(label: 'Comment', value: commentKarma),
                  const SizedBox(width: 8),
                  _KarmaChip(label: 'Award', value: awardKarma),
                  const Spacer(),
                  Text('$totalKarma karma',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: DesignTokens.primary)),
                ],
              ),
              if (!isOwnProfile) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (onFollow != null)
                      FilledButton.tonal(
                        onPressed: onFollow,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(isFollowing ? 'Following' : 'Follow',
                            style: const TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(width: 8),
                    if (onBlock != null)
                      TextButton(
                        onPressed: onBlock,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(isBlocked ? 'Unblock' : 'Block',
                            style: const TextStyle(
                                fontSize: 12,
                                color: DesignTokens.textSecondary)),
                      ),
                  ],
                ),
              ],
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(bio,
                    style: const TextStyle(
                        fontSize: 13, color: DesignTokens.textSecondary)),
              ],
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: DesignTokens.textTertiary),
                    const SizedBox(width: 4),
                    Text('Joined ${_formatDate(createdAt)}',
                        style: const TextStyle(
                            fontSize: 11, color: DesignTokens.textTertiary)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

class _KarmaChip extends StatelessWidget {
  final String label;
  final int value;
  const _KarmaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: DesignTokens.primary)),
    );
  }
}
