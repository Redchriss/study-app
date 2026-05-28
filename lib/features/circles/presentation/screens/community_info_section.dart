import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

/// Community info section with name, member count, join/fav buttons, description.
class CommunityInfoSection extends StatelessWidget {
  final Map<String, dynamic> community;
  final ThemeData theme;
  final bool isMember;
  final bool isFav;
  final int memberCount;
  final String Function(int) formatCount;
  final String slug;
  final VoidCallback onFavToggle;
  final VoidCallback onJoinToggle;

  const CommunityInfoSection({
    super.key,
    required this.community,
    required this.theme,
    required this.isMember,
    required this.isFav,
    required this.memberCount,
    required this.formatCount,
    required this.slug,
    required this.onFavToggle,
    required this.onJoinToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('y/${community['name']}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text('${formatCount(memberCount)} members',
                        style: const TextStyle(
                            color: DesignTokens.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              Mutation(
                options: MutationOptions(document: gql(kJoinCommunity)),
                builder: (joinRun, joinResult) {
                  return Mutation(
                    options: MutationOptions(document: gql(kToggleFavourite)),
                    builder: (favRun, favResult) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isMember)
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.star : Icons.star_border,
                                color: isFav ? DesignTokens.warning : null,
                              ),
                              onPressed: () {
                                favRun({'slug': slug});
                                onFavToggle();
                              },
                            ),
                          const SizedBox(width: 4),
                          FilledButton.tonal(
                            onPressed: () {
                              if (isMember) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Leave community?'),
                                    content:
                                        Text('Leave y/${community['name']}?'),
                                    actions: [
                                      TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx),
                                          child: const Text('Cancel')),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          context.go('/');
                                        },
                                        child: const Text('Leave',
                                            style: TextStyle(
                                                color: DesignTokens.error)),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                joinRun({'slug': slug});
                                onJoinToggle();
                              }
                            },
                            child: Text(isMember ? 'Joined' : 'Join'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
          if (community['description'] != null &&
              community['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(community['description'].toString(),
                  style: const TextStyle(
                      color: DesignTokens.textSecondary, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}
