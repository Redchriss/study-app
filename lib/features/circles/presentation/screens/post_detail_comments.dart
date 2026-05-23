import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
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
        const Icon(Icons.chat_bubble_outline_rounded,
            size: 18, color: DesignTokens.textTertiary),
        const SizedBox(width: 4),
        Text('${(post['commentCount'] as num?)?.toInt() ?? 0}',
            style: const TextStyle(fontSize: 13, color: DesignTokens.textTertiary)),
        const Spacer(),
        const Icon(Icons.bookmark_outline_rounded,
            size: 18, color: DesignTokens.textTertiary),
        const SizedBox(width: 4),
        Text('${(post['awardCount'] as num?)?.toInt() ?? 0} awards',
            style: const TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
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
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
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
        final comments =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

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
            ...comments.map((c) => _CommentItem(
                  comment: c,
                  postId: postId,
                  onRefetch: refetch,
                )),
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
                        final prevData = Map<String, dynamic>.from(
                            prev?['postComments'] ?? {});
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

class _CommentItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final VoidCallback? onRefetch;

  const _CommentItem({
    required this.comment,
    required this.postId,
    this.onRefetch,
  });

  @override
  ConsumerState<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<_CommentItem> {
  final _replyCtrl = TextEditingController();
  bool _showReply = false;
  bool _sendingReply = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReply() async {
    final body = _replyCtrl.text.trim();
    if (body.isEmpty || _sendingReply) return;
    setState(() => _sendingReply = true);
    try {
      final client = ref.read(graphqlClientProvider);
      final result = await client.mutate(MutationOptions(
        document: gql(kAddComment),
        variables: {
          'postId': widget.postId,
          'body': body,
          'parentId': widget.comment['id'],
        },
      ));
      if (!mounted) return;
      if (result.hasException) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(graphQLErrorMessage(result.exception, 'Could not reply')),
          backgroundColor: DesignTokens.error,
        ));
        return;
      }
      _replyCtrl.clear();
      setState(() => _showReply = false);
      widget.onRefetch?.call();
    } finally {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = widget.comment['author'] as Map<String, dynamic>?;
    final isDeleted = widget.comment['isDeleted'] == true;
    final depth = (widget.comment['depth'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(left: math.min(depth * 12, 48).toDouble()),
      decoration: BoxDecoration(
        border: depth > 0
            ? Border(
                left: BorderSide(
                    color: DesignTokens.border.withValues(alpha: 0.3),
                    width: 2))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: isDeleted
                ? const Text('[deleted]',
                    style: TextStyle(
                        color: DesignTokens.textTertiary,
                        fontStyle: FontStyle.italic))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('u/${author?['username'] ?? 'unknown'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 12)),
                          if (widget.comment['isPinned'] == true) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.push_pin_rounded,
                                size: 12, color: DesignTokens.warning),
                          ],
                          if (widget.comment['isAnswer'] == true) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.check_circle,
                                size: 12, color: DesignTokens.success),
                          ],
                          const SizedBox(width: 8),
                          CommentVoteButtons(
                            commentId: widget.comment['id'].toString(),
                            upvotes: (widget.comment['fuzzedUpvotes'] as num?)
                                    ?.toInt() ??
                                0,
                            downvotes:
                                (widget.comment['fuzzedDownvotes'] as num?)
                                        ?.toInt() ??
                                    0,
                            score: (widget.comment['fuzzedScore'] as num?)
                                    ?.toInt() ??
                                0,
                          ),
                          const SizedBox(width: 8),
                          Text(
                              _timeAgo(
                                  widget.comment['createdAt']?.toString() ??
                                      ''),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: DesignTokens.textTertiary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (widget.comment['bodyHtml'] != null &&
                          widget.comment['bodyHtml'].toString().isNotEmpty)
                        Text(
                          widget.comment['bodyHtml']
                              .toString()
                              .replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        )
                      else
                        Text(widget.comment['body']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13, height: 1.4)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () =>
                                setState(() => _showReply = !_showReply),
                            icon: const Icon(Icons.reply_rounded, size: 14),
                            label: Text(_showReply ? 'Cancel' : 'Reply',
                                style: const TextStyle(
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
                            onPressed: () => _reportComment(context),
                            icon: const Icon(Icons.flag_outlined, size: 14),
                            label: const Text('Report',
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
                      if (_showReply) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _replyCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Write a reply...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  isDense: true,
                                ),
                                maxLines: 2,
                                minLines: 1,
                                textInputAction: TextInputAction.send,
                                onSubmitted: (_) => _submitReply(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: _sendingReply
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.send_rounded,
                                      color: DesignTokens.primary),
                              onPressed: _submitReply,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  void _reportComment(BuildContext context) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: const Text('Report Comment'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(hintText: 'Reason...'),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text),
              child: const Text('Report'),
            ),
          ],
        );
      },
    );
    if (reason == null || reason.trim().isEmpty) return;
    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kReportComment),
      variables: {'commentId': widget.comment['id'], 'reason': reason},
    ));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comment reported')),
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
