import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class PostDetailActionBar extends StatelessWidget {
  final String postId;
  final bool isBookmarked;
  final bool awarding;
  final int? userVote;
  final int score;
  final int commentCount;
  final VoidCallback onToggleSave, onGiveAward;
  final void Function(int) onVote;

  const PostDetailActionBar({
    super.key,
    required this.postId,
    required this.isBookmarked,
    required this.awarding,
    required this.userVote,
    required this.score,
    required this.commentCount,
    required this.onToggleSave,
    required this.onGiveAward,
    required this.onVote,
  });

  String _formatScore(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.arrow_upward_rounded,
            label: _formatScore(score),
            active: userVote == 1,
            activeColor: DesignTokens.primary,
            onTap: () => onVote(1),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => onVote(-1),
            child: Icon(Icons.arrow_downward_rounded,
                size: 18,
                color: userVote == -1
                    ? DesignTokens.error
                    : DesignTokens.textTertiary),
          ),
          const SizedBox(width: 12),
          _ActionChip(
            icon: Icons.chat_bubble_outline_rounded,
            label: '$commentCount',
            active: false,
            activeColor: DesignTokens.textTertiary,
            onTap: () {},
          ),
          const Spacer(),
          if (awarding)
            const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
              onPressed: onGiveAward,
              icon: const Icon(Icons.card_giftcard_outlined,
                  size: 18, color: DesignTokens.warning),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
              tooltip: 'Give Award',
            ),
          IconButton(
            onPressed: onToggleSave,
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                size: 18,
                color: isBookmarked
                    ? DesignTokens.warning
                    : DesignTokens.textSecondary),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            tooltip: isBookmarked ? 'Saved' : 'Save',
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.1)
              : DesignTokens.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: active ? activeColor : DesignTokens.textSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? activeColor : DesignTokens.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}
