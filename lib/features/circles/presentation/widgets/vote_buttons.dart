import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class VoteButtons extends ConsumerWidget {
  final String postId;
  final int upvotes;
  final int downvotes;
  final int score;
  final int? userVote;
  final VoidCallback? onVoteChanged;

  const VoteButtons({
    super.key,
    required this.postId,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    this.userVote,
    this.onVoteChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Mutation(
      options: MutationOptions(document: gql(kVotePost)),
      builder: (runMutation, result) {
        void vote(int direction) {
          if (result?.isLoading ?? false) return;
          runMutation({'postId': postId, 'direction': direction});
          onVoteChanged?.call();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => vote(1),
              child: Icon(
                Icons.arrow_upward_rounded,
                size: 20,
                color: userVote == 1
                    ? DesignTokens.primary
                    : DesignTokens.textTertiary,
              ),
            ),
            Text(
              _formatScore(score),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: userVote == 1
                    ? DesignTokens.primary
                    : userVote == -1
                        ? DesignTokens.error
                        : DesignTokens.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () => vote(-1),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 20,
                color: userVote == -1
                    ? DesignTokens.error
                    : DesignTokens.textTertiary,
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatScore(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class CommentVoteButtons extends ConsumerWidget {
  final String commentId;
  final int upvotes;
  final int downvotes;
  final int score;
  final int? userVote;

  const CommentVoteButtons({
    super.key,
    required this.commentId,
    required this.upvotes,
    required this.downvotes,
    required this.score,
    this.userVote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Mutation(
      options: MutationOptions(document: gql(kVoteComment)),
      builder: (runMutation, result) {
        void vote(int direction) {
          if (result?.isLoading ?? false) return;
          runMutation({'commentId': commentId, 'direction': direction});
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => vote(1),
              child: Icon(Icons.arrow_upward_rounded,
                  size: 16,
                  color: userVote == 1
                      ? DesignTokens.primary
                      : DesignTokens.textTertiary),
            ),
            const SizedBox(width: 4),
            Text(
              _formatScore(score),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: userVote == 1
                    ? DesignTokens.primary
                    : userVote == -1
                        ? DesignTokens.error
                        : DesignTokens.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => vote(-1),
              child: Icon(Icons.arrow_downward_rounded,
                  size: 16,
                  color: userVote == -1
                      ? DesignTokens.error
                      : DesignTokens.textTertiary),
            ),
          ],
        );
      },
    );
  }

  String _formatScore(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
