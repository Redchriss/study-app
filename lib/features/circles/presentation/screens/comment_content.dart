import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/vote_buttons.dart';

String timeAgo(String iso) {
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

class CommentContent extends StatelessWidget {
  final Map<String, dynamic>? author;
  final String bodyHtml;
  final String body;
  final bool isPinned;
  final bool isAnswer;
  final bool isCollapsed;
  final VoidCallback onExpand;
  final String commentId;
  final int upvotes;
  final int downvotes;
  final int score;
  final String timeAgo;

  const CommentContent({
    super.key,
    required this.author,
    required this.bodyHtml,
    required this.body,
    required this.isPinned,
    required this.isAnswer,
    required this.isCollapsed,
    required this.onExpand,
    required this.commentId,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    required this.timeAgo,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Text(author!['flairText'].toString(),
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
              commentId: commentId,
              upvotes: upvotes,
              downvotes: downvotes,
              score: score,
            ),
            const SizedBox(width: 8),
            Text(timeAgo,
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textTertiary)),
          ],
        ),
        const SizedBox(height: 4),
        if (isCollapsed)
          GestureDetector(
            onTap: onExpand,
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
              p: const TextStyle(
                  fontSize: 13, height: 1.4, color: DesignTokens.textPrimary),
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
          Text(body, style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }
}
