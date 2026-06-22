import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'user_profile_posts_tab.dart';
import 'user_profile_comments_tab.dart';
import 'user_profile_header.dart';
import 'saved_tab.dart';
import 'ach_icon.dart';

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
              appBar: AppBar(), body: const Center(child: LoadingWidget()));
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
              body: const Center(child: Text('User not found')));
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
              ProfileHeader(
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
                                child: Icon(achIcon(ach?['icon']?.toString()),
                                    color: DesignTokens.primary, size: 22),
                              ),
                              const SizedBox(height: 4),
                              Text(ach?['name']?.toString() ?? '',
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
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
                                              c['icon'].toString()))
                                      : const CircleAvatar(
                                          radius: 10,
                                          child: Text('y',
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white))),
                                  label: Text('y/${c['name']}',
                                      style: const TextStyle(fontSize: 11)),
                                  onPressed: () => context.push('/y/${c['name']}'),
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
                    if (_isOwnProfile)
                      const SavedTab()
                    else
                      const SizedBox.shrink(),
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
}
