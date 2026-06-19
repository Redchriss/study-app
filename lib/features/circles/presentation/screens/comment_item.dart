import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'comment_actions.dart';
import 'comment_content.dart';
import 'comment_mod_menu.dart';

class CommentItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final VoidCallback? onRefetch;
  final bool isPending;
  final VoidCallback? onRetry;
  final bool canModerate;
  final bool canMarkAnswer;
  const CommentItem({
    super.key,
    required this.comment,
    required this.postId,
    this.onRefetch,
    this.isPending = false,
    this.onRetry,
    this.canModerate = false,
    this.canMarkAnswer = false,
  });

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem> {
  final _replyCtrl = TextEditingController();
  bool _showReply = false;
  bool _sendingReply = false;
  bool _collapsed = false;

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
    final isRemoved = widget.comment['isRemoved'] == true;
    final depth = math.min((widget.comment['depth'] as num?)?.toInt() ?? 0, 8);
    final isPinned = widget.comment['isPinned'] == true;
    final isAnswer = widget.comment['isAnswer'] == true;
    final isCollapsed = widget.comment['isCollapsed'] == true || _collapsed;
    final bodyHtml = widget.comment['bodyHtml']?.toString() ?? '';

    final threadColors = [
      DesignTokens.primary,
      DesignTokens.success,
      DesignTokens.warning,
      DesignTokens.error,
      DesignTokens.info,
      DesignTokens.accent,
    ];
    final threadColor = threadColors[depth % threadColors.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(left: depth > 0 ? 12.0 : 0),
      decoration: BoxDecoration(
        border: depth > 0
            ? Border(
                left: BorderSide(
                    color: threadColor.withValues(alpha: 0.25), width: 2))
            : null,
      ),
      child: Opacity(
        opacity: widget.isPending ? 0.6 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isPending)
              _buildPendingIndicator()
            else if (widget.onRetry != null)
              _buildRetryIndicator(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: isDeleted || isRemoved
                  ? _buildDeletedOrRemoved(isDeleted)
                  : CommentContent(
                      author: author,
                      bodyHtml: bodyHtml,
                      body: widget.comment['body']?.toString() ?? '',
                      isPinned: isPinned,
                      isAnswer: isAnswer,
                      isCollapsed: isCollapsed,
                      onExpand: () => setState(() => _collapsed = false),
                      commentId: widget.comment['id'].toString(),
                      upvotes:
                          (widget.comment['fuzzedUpvotes'] as num?)?.toInt() ??
                              0,
                      downvotes: (widget.comment['fuzzedDownvotes'] as num?)
                              ?.toInt() ??
                          0,
                      score:
                          (widget.comment['fuzzedScore'] as num?)?.toInt() ?? 0,
                      timeAgo: timeAgo(
                          widget.comment['createdAt']?.toString() ?? ''),
                    ),
            ),
            if (!isDeleted && !isRemoved)
              CommentActionRow(
                showReply: _showReply,
                collapsed: _collapsed,
                onReply: () => setState(() {
                  _showReply = !_showReply;
                  _collapsed = false;
                }),
                onSave: () =>
                    saveComment(ref, widget.comment['id'].toString(), context),
                onCollapse: () => setState(() => _collapsed = !_collapsed),
                onReport: () => reportComment(
                    ref, widget.comment['id'].toString(), context),
                trailing: (widget.canModerate || widget.canMarkAnswer)
                    ? CommentModMenu(
                        commentId: widget.comment['id'].toString(),
                        postId: widget.postId,
                        isPinned: isPinned,
                        isAnswer: isAnswer,
                        canModerate: widget.canModerate,
                        canMarkAnswer: widget.canMarkAnswer,
                        onChanged: widget.onRefetch,
                      )
                    : null,
              ),
            if (_showReply)
              CommentReplyInput(
                controller: _replyCtrl,
                sending: _sendingReply,
                onSubmit: _submitReply,
              ),
            const Divider(height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5)),
          const SizedBox(width: 4),
          const Text('Posting...',
              style: TextStyle(fontSize: 10, color: DesignTokens.textTertiary)),
        ],
      ),
    );
  }

  Widget _buildRetryIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 14, color: DesignTokens.error),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: widget.onRetry,
            child: const Text('Retry',
                style: TextStyle(
                    fontSize: 11,
                    color: DesignTokens.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDeletedOrRemoved(bool isDeleted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        isDeleted ? '[deleted]' : '[removed by moderator]',
        style: const TextStyle(
            color: DesignTokens.textTertiary, fontStyle: FontStyle.italic),
      ),
    );
  }
}
