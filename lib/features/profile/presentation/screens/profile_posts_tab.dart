import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ProfilePostsTab extends StatelessWidget {
  final String username;
  const ProfilePostsTab({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kUserPosts),
        variables: {'username': username, 'sort': 'new', 'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 80, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 80, radius: 12),
              ShimmerBox(height: 80, radius: 12),
            ]),
          );
        }

        final data = result.data?['userPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final posts =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.article_outlined, size: 48, color: DesignTokens.textTertiary),
                  SizedBox(height: 12),
                  Text('No posts yet',
                      style: TextStyle(color: DesignTokens.textSecondary, fontSize: 15)),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll is ScrollEndNotification &&
                  scroll.metrics.pixels >=
                      scroll.metrics.maxScrollExtent - 200) {
                final pageInfo = data?['pageInfo'];
                if (pageInfo?['hasNextPage'] == true) {
                  fetchMore?.call(FetchMoreOptions(
                    variables: {'after': pageInfo['endCursor']},
                    updateQuery: (prev, next) {
                      if (next?['userPosts'] == null) return prev;
                      final merged = Map<String, dynamic>.from(prev ?? {});
                      final prevData =
                          Map<String, dynamic>.from(prev?['userPosts'] ?? {});
                      final nextData =
                          Map<String, dynamic>.from(next!['userPosts']);
                      final prevEdges = (prevData['edges'] as List?) ?? [];
                      final nextEdges = (nextData['edges'] as List?) ?? [];
                      merged['userPosts'] = {
                        ...nextData,
                        'edges': [...prevEdges, ...nextEdges],
                      };
                      return merged;
                    },
                  ));
                }
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              itemCount: posts.length,
              itemBuilder: (_, i) => _PostListItem(
                post: posts[i],
                onTap: () {
                  final c = posts[i]['community'];
                  if (c != null) {
                    context.push('/y/${c['slug']}/post/${posts[i]['slug']}');
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PostListItem extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback onTap;

  const _PostListItem({required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final community = post['community'] as Map<String, dynamic>?;
    final title = post['title']?.toString() ?? '';
    final score = (post['fuzzedScore'] as num?)?.toInt() ?? 0;
    final commentCount = (post['commentCount'] as num?)?.toInt() ?? 0;
    final createdAt = post['createdAt']?.toString() ?? '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  const Icon(Icons.arrow_upward,
                      size: 14, color: DesignTokens.textTertiary),
                  Text('$score',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700,
                          color: DesignTokens.textSecondary)),
                  const Icon(Icons.arrow_downward,
                      size: 14, color: DesignTokens.textTertiary),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (community != null) ...[
                        Text('y/${community['slug'] ?? ''}',
                            style: const TextStyle(
                                fontSize: 11, color: DesignTokens.primary)),
                        const SizedBox(width: 6),
                      ],
                      Text(_timeAgo(createdAt),
                          style: const TextStyle(
                              fontSize: 11, color: DesignTokens.textTertiary)),
                      const SizedBox(width: 6),
                      Icon(Icons.chat_bubble_outline,
                          size: 12, color: DesignTokens.textTertiary),
                      const SizedBox(width: 2),
                      Text('$commentCount',
                          style: const TextStyle(
                              fontSize: 11, color: DesignTokens.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (_) {
      return '';
    }
  }
}
