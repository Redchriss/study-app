import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/vote_buttons.dart';

class CommentItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> comment;
  final String postId;
  final VoidCallback? onRefetch;
  final bool isPending;
  final VoidCallback? onRetry;
  const CommentItem({
    super.key,
    required this.comment,
    required this.postId,
    this.onRefetch,
    this.isPending = false,
    this.onRetry,
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

  Future<void> _saveComment() async {
    final client = ref.read(graphqlClientProvider);
    await client.mutate(MutationOptions(
      document: gql(kSaveComment),
      variables: {'commentId': widget.comment['id']},
    ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment saved')),
      );
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
                  : _buildCommentContent(
                      author, bodyHtml, isPinned, isAnswer, isCollapsed, depth),
            ),
            if (!isDeleted && !isRemoved) _buildActionRow(),
            if (_showReply) _buildReplyInput(),
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
          const SizedBox(width: 12, height: 12,
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

  Widget _buildCommentContent(Map<String, dynamic>? author, String bodyHtml,
      bool isPinned, bool isAnswer, bool isCollapsed, int depth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('u/${author?['username'] ?? 'unknown'}',
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
            if (author?['flairText'] != null &&
                author!['flairText'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(author['flairText'].toString(),
                      style: const TextStyle(
                          fontSize: 9, color: DesignTokens.primary)),
                ),
              ),
            if (isPinned) ...[
              const SizedBox(width: 6),
              const Icon(Icons.push_pin_rounded,
                  size: 12, color: DesignTokens.warning),
            ],
            if (isAnswer) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle,
                  size: 12, color: DesignTokens.success),
            ],
            const SizedBox(width: 8),
            CommentVoteButtons(
              commentId: widget.comment['id'].toString(),
              upvotes:
                  (widget.comment['fuzzedUpvotes'] as num?)?.toInt() ?? 0,
              downvotes:
                  (widget.comment['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
              score: (widget.comment['fuzzedScore'] as num?)?.toInt() ?? 0,
            ),
            const SizedBox(width: 8),
            Text(_timeAgo(widget.comment['createdAt']?.toString() ?? ''),
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
          ],
        ),
        const SizedBox(height: 4),
        if (isCollapsed)
          GestureDetector(
            onTap: () => setState(() => _collapsed = false),
            child: Text(
              '[collapsed — tap to show]',
              style: TextStyle(
                  fontSize: 12,
                  color: DesignTokens.textTertiary,
                  fontStyle: FontStyle.italic),
            ),
          )
        else if (bodyHtml.isNotEmpty)
          Markdown(
            data: bodyHtml,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(fontSize: 13, height: 1.4, color: DesignTokens.textPrimary),
              strong: const TextStyle(fontWeight: FontWeight.w700),
              em: const TextStyle(fontStyle: FontStyle.italic),
              code: TextStyle(
                  fontSize: 12,
                  backgroundColor: DesignTokens.surfaceVariant,
                  color: DesignTokens.primary),
              a: const TextStyle(color: DesignTokens.primary),
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          )
        else
          Text(widget.comment['body']?.toString() ?? '',
              style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }

  Widget _buildActionRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => setState(() {
              _showReply = !_showReply;
              _collapsed = false;
            }),
            icon: const Icon(Icons.reply_rounded, size: 14),
            label: Text(_showReply ? 'Cancel' : 'Reply',
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _saveComment,
            icon: const Icon(Icons.bookmark_outline, size: 14),
            label: const Text('Save',
                style: TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => setState(() => _collapsed = !_collapsed),
            icon: Icon(
                _collapsed
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                size: 14),
            label: Text(_collapsed ? 'Expand' : 'Collapse',
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: () => _reportComment(context),
            icon: const Icon(Icons.flag_outlined, size: 14),
            label: const Text('Report',
                style: TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyInput() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replyCtrl,
              decoration: const InputDecoration(
                hintText: 'Write a reply...',
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send_rounded, color: DesignTokens.primary),
            onPressed: _submitReply,
          ),
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
              autofocus: true),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, ctrl.text),
                child: const Text('Report')),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Comment reported')));
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
