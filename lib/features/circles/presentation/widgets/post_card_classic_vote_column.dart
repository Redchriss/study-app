import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class ClassicVoteColumn extends ConsumerWidget {
  final String postId;
  final int score;
  final int? userVote;
  final bool dark;

  const ClassicVoteColumn({
    super.key,
    required this.postId,
    required this.score,
    required this.dark,
    this.userVote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Mutation(
      options: MutationOptions(document: gql(kVotePost)),
      builder: (runMutation, result) {
        void vote(int dir) {
          if (result?.isLoading ?? false) return;
          runMutation({'postId': postId, 'direction': dir});
        }

        final upColor =
            userVote == 1 ? DesignTokens.secondary : DesignTokens.textTertiary;
        final downColor =
            userVote == -1 ? DesignTokens.error : DesignTokens.textTertiary;
        final scoreColor = userVote == 1
            ? DesignTokens.secondary
            : userVote == -1
                ? DesignTokens.error
                : DesignTokens.textSecondary;

        return Container(
          width: 38,
          decoration: BoxDecoration(
            gradient: DesignTokens.brandGradientSubtle(dark),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => vote(1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_upward_rounded,
                      size: 16, color: upColor),
                ),
              ),
              Text(
                _fmt(score),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: scoreColor),
              ),
              GestureDetector(
                onTap: () => vote(-1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Icon(Icons.arrow_downward_rounded,
                      size: 16, color: downColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
