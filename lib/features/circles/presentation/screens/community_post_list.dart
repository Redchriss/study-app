import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../providers/pending_posts_provider.dart';
import '../widgets/post_card.dart';

class CommunityPostList extends StatefulWidget {
  final String slug;
  final String sort;
  final String timeFilter;
  final bool isMember;
  final String? postType;
  final String? flairId;

  const CommunityPostList({
    super.key,
    required this.slug,
    required this.sort,
    this.timeFilter = 'all',
    required this.isMember,
    this.postType,
    this.flairId,
  });

  @override
  State<CommunityPostList> createState() => _CommunityPostListState();
}

class _CommunityPostListState extends State<CommunityPostList> {
  final _scrollCtrl = ScrollController();
  bool _loadingMore = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Widget _pendingPostCard(PendingEntry entry, BuildContext context) {
    final isSubmitting = entry.status == PendingStatus.submitting;
    final hasFailed = entry.status == PendingStatus.failed;
    final post = entry.data;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: (Theme.of(context).brightness == Brightness.dark
                ? DesignTokens.darkSurface
                : DesignTokens.surface)
            .withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: hasFailed
              ? DesignTokens.error.withValues(alpha: 0.5)
              : (Theme.of(context).brightness == Brightness.dark
                  ? DesignTokens.darkBorder
                  : DesignTokens.border),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSubmitting)
              const SizedBox(
                width: double.infinity,
                child: LinearProgressIndicator(),
              ),
            if (hasFailed)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 14, color: DesignTokens.error),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(entry.error ?? 'Post failed',
                          style: const TextStyle(
                              fontSize: 11, color: DesignTokens.error)),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                if (isSubmitting)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5)),
                  ),
                Expanded(
                  child: Text(post['title']?.toString() ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ],
            ),
            if (post['body'] != null && post['body'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(post['body'].toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12, color: DesignTokens.textSecondary)),
              ),
          ],
        ),
      ),
    );
  }

  void _onScroll(ScrollNotification info, FetchMore? fetchMore,
      Map<String, dynamic>? data) {
    if (_loadingMore || info is! ScrollUpdateNotification) return;
    if (info.metrics.pixels < info.metrics.maxScrollExtent - 200) return;
    if (data?['pageInfo']?['hasNextPage'] != true) return;
    _loadingMore = true;
    fetchMore
        ?.call(FetchMoreOptions(
      variables: {'after': data!['pageInfo']['endCursor']},
      updateQuery: (prev, next) {
        if (next?['communityPosts'] == null) return prev;
        final merged = Map<String, dynamic>.from(prev ?? {});
        final prevData =
            Map<String, dynamic>.from(prev?['communityPosts'] ?? {});
        final nextData = Map<String, dynamic>.from(next!['communityPosts']);
        final prevEdges = (prevData['edges'] as List?) ?? [];
        final nextEdges = (nextData['edges'] as List?) ?? [];
        merged['communityPosts'] = {
          ...nextData,
          'edges': [...prevEdges, ...nextEdges],
        };
        return merged;
      },
    ))
        .then((_) {
      if (mounted) {
        setState(() => _loadingMore = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityPosts),
        variables: {
          'slug': widget.slug,
          'sort': widget.sort,
          'limit': 25,
          if (widget.timeFilter != 'all')
            'timeFilter': widget.timeFilter.toUpperCase(),
          if (widget.postType != null) 'postType': widget.postType,
          if (widget.flairId != null) 'flairId': widget.flairId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 130, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 130, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 130, radius: 12),
            ]),
          );
        }
        if (result.hasException) {
          return ErrorState(
            message:
                graphQLErrorMessage(result.exception, 'Could not load posts'),
            onRetry: () => refetch?.call(),
          );
        }

        final data = result.data?['communityPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final posts =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (posts.isEmpty) {
          return EmptyState(
            icon: Icons.article_outlined,
            title: 'No posts yet',
            subtitle: widget.isMember
                ? 'Be the first to post!'
                : 'Join to participate.',
            actionLabel: widget.isMember ? 'Create Post' : null,
            onAction: widget.isMember
                ? () => context.push('/y/${widget.slug}/submit')
                : null,
          );
        }

        return Consumer(
          builder: (context, ref, _) {
            final pendings = ref
                .watch(pendingPostsProvider)
                .where((e) => e.groupKey == widget.slug && e.type == 'post')
                .toList();
            return NotificationListener<ScrollNotification>(
              onNotification: (info) {
                _onScroll(info, fetchMore, data);
                return false;
              },
              child: Column(
                children: [
                  ...pendings.map((e) => _pendingPostCard(e, context)),
                  ...posts.map((p) => PostCard(
                        post: p,
                        onTap: () =>
                            context.push('/y/${widget.slug}/post/${p['slug']}'),
                      )),
                  if (_loadingMore)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
