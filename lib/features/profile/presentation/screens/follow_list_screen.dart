import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';

class FollowListScreen extends StatefulWidget {
  final String initialTab;
  const FollowListScreen({super.key, this.initialTab = 'followers'});

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.initialTab == 'following') {
      _tabCtrl.index = 1;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connections',
            style: TextStyle(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
          labelColor: DesignTokens.primary,
          unselectedLabelColor: DesignTokens.textSecondary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _UserList(query: kMyFollowers, dataKey: 'myFollowers', emptyTitle: 'No followers yet'),
          _UserList(query: kMyFollowing, dataKey: 'myFollowing', emptyTitle: 'Not following anyone'),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final String query;
  final String dataKey;
  final String emptyTitle;

  const _UserList({
    required this.query,
    required this.dataKey,
    required this.emptyTitle,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Query(
      options: QueryOptions(
        document: gql(query),
        variables: const {'limit': 50},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (result.hasException) {
          return ErrorState(
            message: graphQLErrorMessage(result.exception, 'Could not load'),
            onRetry: () => refetch?.call(),
          );
        }
        final users = (result.data?[dataKey] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        if (users.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline_rounded,
            title: emptyTitle,
            subtitle: 'When people follow you or you follow others, they\'ll appear here.',
          );
        }
        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (_, i) {
              final u = users[i];
              final profile = u['profile'] as Map<String, dynamic>?;
              final avatarUrl = profile?['avatarUrl']?.toString() ?? '';
              final username = u['username']?.toString() ?? '';
              final bio = profile?['bio']?.toString() ?? '';
              final totalKarma =
                  (profile?['totalKarma'] as num?)?.toInt() ?? 0;
              return _UserCard(
                username: username,
                avatarUrl: avatarUrl,
                bio: bio,
                totalKarma: totalKarma,
                dark: dark,
                onTap: () => context.push('/u/$username'),
              );
            },
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final String username;
  final String avatarUrl;
  final String bio;
  final int totalKarma;
  final bool dark;
  final VoidCallback onTap;

  const _UserCard({
    required this.username,
    required this.avatarUrl,
    required this.bio,
    required this.totalKarma,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          border: Border.all(
              color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                  .withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? Text(username[0].toUpperCase(),
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: DesignTokens.primary))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('u/$username',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  if (bio.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(bio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary)),
                  ],
                ],
              ),
            ),
            if (totalKarma > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$totalKarma',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.primary)),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: DesignTokens.textTertiary),
          ],
        ),
      ),
    );
  }
}
