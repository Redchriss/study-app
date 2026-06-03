import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class JoinFavButtons extends StatelessWidget {
  final String slug;
  final bool isMember;
  final bool isFav;
  final VoidCallback onJoinChanged;

  const JoinFavButtons({
    super.key,
    required this.slug,
    required this.isMember,
    required this.isFav,
    required this.onJoinChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMember)
          Mutation(
            options: MutationOptions(document: gql(kToggleFavourite)),
            builder: (runFav, _) {
              return IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? DesignTokens.warning : null,
                  size: 20,
                ),
                onPressed: () {
                  runFav({'slug': slug});
                  onJoinChanged();
                },
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              );
            },
          ),
        Mutation(
          options: MutationOptions(
            document: gql(isMember ? kLeaveCommunity : kJoinCommunity),
          ),
          builder: (runJoin, joinResult) {
            final busy = joinResult?.isLoading ?? false;
            return FilledButton.tonal(
              onPressed: busy
                  ? null
                  : () {
                      if (isMember) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Leave community?'),
                            content: Text('Leave y/$slug?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  runJoin({'slug': slug});
                                  onJoinChanged();
                                },
                                child: const Text('Leave',
                                    style:
                                        TextStyle(color: DesignTokens.error)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        runJoin({'slug': slug});
                        onJoinChanged();
                      }
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Text(
                      isMember ? 'Joined' : 'Join',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
            );
          },
        ),
      ],
    );
  }
}
