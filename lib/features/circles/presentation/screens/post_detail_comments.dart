import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/vote_buttons.dart';

class PostDetailStats extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostDetailStats({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        VoteButtons(
          postId: post['id'].toString(),
          upvotes: (post['fuzzedUpvotes'] as num?)?.toInt() ?? 0,
          downvotes: (post['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
          score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
        ),
        const SizedBox(width: 16),
        Icon(Icons.chat_bubble_outline_rounded, size: 18, color: DesignTokens.textTertiary),
        const SizedBox(width: 4),
        Text('${(post['commentCount'] as num?)?.toInt() ?? 0}',
            style: TextStyle(fontSize: 13, color: DesignTokens.textTertiary)),
        const Spacer(),
        Icon(Icons.bookmark_outline_rounded, size: 18, color: DesignTokens.textTertiary),
        const SizedBox(width: 4),
        Text('${(post['awardCount'] as num?)?.toInt() ?? 0} awards',
            style: TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
        const SizedBox(width: 16),
      ],
    );
  }
}

class PostCommentsList extends StatelessWidget {
  final String postId;
  final String sort;
  const PostCommentsList({super.key, required this.postId, required this.sort});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kPostComments),
        variables: {'postId': postId, 'sort': sort, 'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              ShimmerBox(height: 60, radius: 8),
              SizedBox(height: 8),
              ShimmerBox(height: 60, radius: 8),
            ]),
          );
        }

        final data = result.data?['postComments'];
        final edges = (data?['edges'] as List?) ?? [];
        final comments = edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No comments yet',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }

        return Column(
          children: [
            ...comments.map((c) => _CommentItem(comment: c, postId: postId)),
            if (data?['pageInfo']?['hasNextPage'] == true)
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () {
                    fetchMore?.call(FetchMoreOptions(
                      variables: {'after': data['pageInfo']['endCursor']},
                      updateQuery: (prev, next) {
                        if (next?['postComments'] == null) return prev;
                        final merged = Map<String, dynamic>.from(prev ?? {});
                        final prevData =
                            Map<String, dynamic>.from(prev?['postComments'] ?? {});
                        final nextData =
                            Map<String, dynamic>.from(next!['postComments']);
                        final prevEdges = (prevData['edges'] as List?) ?? [];
                        final nextEdges = (nextData['edges'] as List?) ?? [];
                        merged['postComments'] = {
                          ...nextData,
                          'edges': [...prevEdges, ...nextEdges],
                        };
                        return merged;
                      },
                    ));
                  },
                  child: const Text('Load more comments'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Map<String, dynamic> comment;
  final String postId;
  const _CommentItem({required this.comment, required this.postId});

  @override
  Widget build(BuildContext context) {
    final author = comment['author'] as Map<String, dynamic>?;
    final isDeleted = comment['isDeleted'] == true;
    final depth = (comment['depth'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(left: math.min(depth * 12, 48).toDouble()),
      decoration: BoxDecoration(
        border: depth > 0
            ? Border(
                left: BorderSide(
                    color: DesignTokens.border.withValues(alpha: 0.3), width: 2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: isDeleted
                ? Text('[deleted]',
                    style: TextStyle(
                        color: DesignTokens.textTertiary,
                        fontStyle: FontStyle.italic))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('u/${author?['username'] ?? 'unknown'}',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                          if (comment['isPinned'] == true) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.push_pin_rounded,
                                size: 12, color: DesignTokens.warning),
                          ],
                          if (comment['isAnswer'] == true) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.check_circle,
                                size: 12, color: DesignTokens.success),
                          ],
                          const SizedBox(width: 8),
                          CommentVoteButtons(
                            commentId: comment['id'].toString(),
                            upvotes:
                                (comment['fuzzedUpvotes'] as num?)?.toInt() ?? 0,
                            downvotes:
                                (comment['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
                            score:
                                (comment['fuzzedScore'] as num?)?.toInt() ?? 0,
                          ),
                          const SizedBox(width: 8),
                          Text(_timeAgo(comment['createdAt']?.toString() ?? ''),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (comment['bodyHtml'] != null &&
                          comment['bodyHtml'].toString().isNotEmpty)
                        Text(
                          comment['bodyHtml'].toString().replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        )
                      else
                        Text(comment['body']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13, height: 1.4)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.reply_rounded, size: 14),
                            label: Text('Reply',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: DesignTokens.textTertiary)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.flag_outlined, size: 14),
                            label: Text('Report',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: DesignTokens.textTertiary)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${diff.inDays ~/ 7}w ago';
    } catch (_) {
      return '';
    }
  }
}
