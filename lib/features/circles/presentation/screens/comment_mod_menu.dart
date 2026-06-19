import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/design_tokens.dart';
import '../providers/circles_providers.dart';

/// Overflow menu surfacing the previously-unreachable comment actions:
/// mark-as-answer (post author) and moderation (approve/pin/distinguish).
/// Renders nothing when the viewer can do neither.
class CommentModMenu extends ConsumerWidget {
  final String commentId;
  final String postId;
  final bool isPinned;
  final bool isAnswer;
  final bool canModerate;
  final bool canMarkAnswer;
  final VoidCallback? onChanged;

  const CommentModMenu({
    super.key,
    required this.commentId,
    required this.postId,
    this.isPinned = false,
    this.isAnswer = false,
    this.canModerate = false,
    this.canMarkAnswer = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = <PopupMenuEntry<String>>[];
    if (canMarkAnswer) {
      entries.add(_item('answer', Icons.verified_rounded,
          isAnswer ? 'Marked as answer' : 'Mark as answer'));
    }
    if (canModerate) {
      entries.add(_item('approve', Icons.check_circle_outline_rounded, 'Approve'));
      entries.add(_item('pin', Icons.push_pin_outlined, isPinned ? 'Pinned' : 'Pin'));
      entries.add(_item(
          'distinguish', Icons.shield_outlined, 'Distinguish as mod'));
    }
    if (entries.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz_rounded,
          size: 16, color: DesignTokens.textTertiary),
      padding: EdgeInsets.zero,
      tooltip: 'Moderate',
      itemBuilder: (_) => entries,
      onSelected: (value) => _handle(context, ref, value),
    );
  }

  PopupMenuItem<String> _item(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DesignTokens.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Future<void> _handle(
      BuildContext context, WidgetRef ref, String value) async {
    final repo = ref.read(circlesRepositoryProvider);
    try {
      switch (value) {
        case 'answer':
          await repo.markAnswer(commentId: commentId, postId: postId);
          break;
        case 'approve':
          await repo.approveComment(commentId);
          break;
        case 'pin':
          await repo.pinComment(commentId);
          break;
        case 'distinguish':
          await repo.distinguishComment(commentId);
          break;
      }
      onChanged?.call();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Done')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error.toString()),
          backgroundColor: DesignTokens.error,
        ));
      }
    }
  }
}
