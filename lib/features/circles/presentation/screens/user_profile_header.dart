import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';

const String kSavedPosts = r'''query SavedPosts { __typename }''';

class ProfileHeader extends StatelessWidget {
  final Map<String, dynamic> profile;
  final String username;
  final bool isOwnProfile;
  final bool isFollowing;
  final bool isBlocked;
  final VoidCallback? onFollow;
  final VoidCallback? onBlock;

  const ProfileHeader({
    super.key,
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
                            width: 72, height: 72, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person, size: 36, color: DesignTokens.primary)),
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Row(
                children: [
                  KarmaChip(label: 'Post', value: postKarma),
                  const SizedBox(width: 8),
                  KarmaChip(label: 'Comment', value: commentKarma),
                  const SizedBox(width: 8),
                  KarmaChip(label: 'Award', value: awardKarma),
                  const Spacer(),
                  Text('$totalKarma karma',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.primary)),
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
                        child: Text(isFollowing ? 'Following' : 'Follow', style: const TextStyle(fontSize: 12)),
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
                            style: const TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/inbox'),
                      icon: const Icon(Icons.message_outlined, size: 14),
                      label: const Text('Message', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: DesignTokens.primary,
                      ),
                    ),
                  ],
                ),
              ],
              if (bio != null && bio.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(bio, style: const TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
              ],
              if (createdAt != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 12, color: DesignTokens.textTertiary),
                    const SizedBox(width: 4),
                    Text('Joined ${_formatDate(createdAt)}',
                        style: const TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
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
    } catch (_) { return ''; }
  }
}

class KarmaChip extends StatelessWidget {
  final String label;
  final int value;
  const KarmaChip({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: DesignTokens.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: DesignTokens.primary)),
    );
  }
}

class SavedTab extends StatelessWidget {
  const SavedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kSavedPosts),
        variables: const {'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result, {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (result.hasException) {
          return ErrorState(
            message: graphQLErrorMessage(result.exception, 'Could not load saved'),
            onRetry: () => refetch?.call(),
          );
        }
        final data = result.data?['savedPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final posts = edges.map((e) => e['node'] as Map<String, dynamic>).toList();
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No saved posts', style: TextStyle(color: DesignTokens.textSecondary)),
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
            subtitle: Text('y/${(posts[i]['community'] as Map?)?['name'] ?? ''}',
                style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}

IconData achIcon(String? icon) {
  switch (icon) {
    case 'streak': return Icons.local_fire_department_rounded;
    case 'posts': return Icons.article_rounded;
    case 'comments': return Icons.chat_rounded;
    case 'karma': return Icons.trending_up_rounded;
    case 'votes': return Icons.arrow_upward_rounded;
    case 'awards': return Icons.auto_awesome_rounded;
    default: return Icons.emoji_events_rounded;
  }
}
