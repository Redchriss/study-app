import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class PostDetailPostCard extends ConsumerWidget {
  final Map<String, dynamic> post;
  final bool dark;
  final dynamic refetch;

  const PostDetailPostCard({
    super.key,
    required this.post,
    required this.dark,
    required this.refetch,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: DesignTokens.primary.withValues(alpha: 0.15)),
        boxShadow: DesignTokens.shadowSm(dark),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.primary
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                    (post['postType'] ?? 'discussion')
                        .toString()
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: DesignTokens.primary)),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      icon: Icon(
                          post['userVote'] == 'up'
                              ? Icons.thumb_up_rounded
                              : Icons.thumb_up_outlined,
                          size: 18,
                          color: post['userVote'] == 'up'
                              ? DesignTokens.primary
                              : DesignTokens.textSecondary),
                      onPressed: () {
                        _vote(ref, post['id'], 'up');
                      },
                    ),
                    Text('${post['score'] ?? 0}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                          minWidth: 32, minHeight: 32),
                      icon: Icon(
                          post['userVote'] == 'down'
                              ? Icons.thumb_down_rounded
                              : Icons.thumb_down_outlined,
                          size: 18,
                          color: post['userVote'] == 'down'
                              ? DesignTokens.error
                              : DesignTokens.textSecondary),
                      onPressed: () {
                        _vote(ref, post['id'], 'down');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.auto_awesome_rounded,
                    size: 22, color: DesignTokens.info),
                tooltip: 'Ask AI to reply',
                style: IconButton.styleFrom(
                    backgroundColor: DesignTokens.info
                        .withValues(alpha: 0.1)),
                onPressed: () async {
                  final client =
                      ref.read(graphqlClientProvider);
                  final result =
                      await client.mutate(MutationOptions(
                    document: gql(kAskAiOnPost),
                    variables: {'postId': post['id']},
                  ));
                  if (context.mounted) {
                    final message = result
                            .data?['askAiOnPost']?['comment']?['body'] ??
                        result.exception?.graphqlErrors
                            .firstOrNull?.message ??
                        'AI replied!';
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                    refetch?.call();
                  }
                },
              ),
            ]),
            const SizedBox(height: 16),
            Text(
              post['body'] ?? '',
              style:
                  const TextStyle(fontSize: 15, height: 1.5),
            ),
            if (post['imageUrl'] != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(post['imageUrl'],
                    width: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const SizedBox()),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: DesignTokens.primary
                      .withValues(alpha: 0.2),
                  child: Text(
                    post['author']?['username']
                            ?.toString()
                            .substring(0, 1)
                            .toUpperCase() ??
                        '?',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: DesignTokens.primary),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                    'Posted by ${post['author']?['username'] ?? 'Anonymous'}',
                    style: const TextStyle(
                        color: DesignTokens.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ]),
    );
  }

  void _vote(WidgetRef ref, String postId, String direction) {
    ref
        .read(graphqlClientProvider)
        .mutate(MutationOptions(
          document: gql(kVotePost),
          variables: {'postId': postId, 'direction': direction},
        ))
        .then((_) {
      refetch?.call();
    });
  }
}
