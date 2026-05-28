import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PostDetailActionBar extends StatelessWidget {
  final String postId;
  final bool isBookmarked;
  final bool awarding;
  final int commentCount;
  final VoidCallback onToggleSave;
  final VoidCallback onGiveAward;
  const PostDetailActionBar({
    super.key,
    required this.postId,
    required this.isBookmarked,
    required this.awarding,
    required this.commentCount,
    required this.onToggleSave,
    required this.onGiveAward,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          awarding
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : TextButton.icon(
                  onPressed: onGiveAward,
                  icon: const Icon(Icons.card_giftcard_outlined, size: 18, color: DesignTokens.warning),
                  label: const Text('Award', style: TextStyle(fontSize: 12, color: DesignTokens.warning)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onToggleSave,
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline, size: 18,
                color: isBookmarked ? DesignTokens.warning : DesignTokens.textSecondary),
            label: Text(isBookmarked ? 'Saved' : 'Save', style: TextStyle(
                fontSize: 12, color: isBookmarked ? DesignTokens.warning : DesignTokens.textSecondary)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Spacer(),
          Icon(Icons.chat_bubble_outline_rounded, size: 16, color: DesignTokens.textTertiary),
          const SizedBox(width: 4),
          Text('$commentCount', style: const TextStyle(fontSize: 12, color: DesignTokens.textTertiary)),
        ],
      ),
    );
  }
}
