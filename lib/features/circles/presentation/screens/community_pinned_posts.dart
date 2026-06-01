import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/post_card.dart';

class PinnedPostsSection extends StatelessWidget {
  final String slug;
  final bool isMember;
  const PinnedPostsSection(
      {super.key, required this.slug, required this.isMember});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityPosts),
        variables: {
          'slug': slug,
          'sort': 'hot',
          'isPinned': true,
          'limit': 2,
        },
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading || result.hasException) {
          return const SizedBox.shrink();
        }
        final data = result.data?['communityPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final pinned =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();
        if (pinned.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.push_pin, size: 14, color: DesignTokens.warning),
                  SizedBox(width: 4),
                  Text('PINNED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.warning,
                        letterSpacing: 0.5,
                      )),
                ],
              ),
            ),
            ...pinned.map((p) => PostCard(
                  post: p,
                  onTap: () => context.push('/y/$slug/post/${p['slug']}'),
                )),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
