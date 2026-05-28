import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/vote_buttons.dart';
import 'comment_item.dart';

class PostDetailStats extends StatelessWidget {
  final Map<String, dynamic> post;
  const PostDetailStats({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 12),
        VoteButtons(
          postId: post['id'].toString(),
          upvotes: (post['fuzzedUpvotes'] as num?)?.toInt() ?? 0,
          downvotes: (post['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
          score: (post['fuzzedScore'] as num?)?.toInt() ?? 0,
        ),
        const SizedBox(width: 16),
        const Icon(Icons.chat_bubble_outline_rounded,
            size: 18, color: DesignTokens.textTertiary),
        const SizedBox(width: 4),
        Text('${(post['commentCount'] as num?)?.toInt() ?? 0}',
            style: const TextStyle(
                fontSize: 13, color: DesignTokens.textTertiary)),
        const Spacer(),
        const Icon(Icons.bookmark_outline_rounded,
            size: 18, color: DesignTokens.textTertiary),
        const SizedBox(width: 4),
        Text('${(post['awardCount'] as num?)?.toInt() ?? 0} awards',
            style: const TextStyle(
                fontSize: 12, color: DesignTokens.textTertiary)),
        const SizedBox(width: 16),
      ],
    );
  }
}

class PostCommentsList extends StatelessWidget {
  final String postId;
  final String sort;
  const PostCommentsList({super.key, required this.postId, required this.sort});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kPostComments),
        variables: {'postId': postId, 'sort': sort, 'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Column(children: [
              ShimmerBox(height: 60, radius: 8),
              SizedBox(height: 8),
              ShimmerBox(height: 60, radius: 8),
            ]),
          );
        }

        final data = result.data?['postComments'];
        final edges = (data?['edges'] as List?) ?? [];
        final comments =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (comments.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('No comments yet',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }

        return Column(
          children: [
            ...comments.map((c) => CommentItem(
                  comment: c,
                  postId: postId,
                  onRefetch: refetch,
                )),
            if (data?['pageInfo']?['hasNextPage'] == true)
              Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton(
                  onPressed: () {
                    fetchMore?.call(FetchMoreOptions(
                      variables: {'after': data['pageInfo']['endCursor']},
                      updateQuery: (prev, next) {
                        if (next?['postComments'] == null) return prev;
                        final merged = Map<String, dynamic>.from(prev ?? {});
                        final prevData = Map<String, dynamic>.from(
                            prev?['postComments'] ?? {});
                        final nextData =
                            Map<String, dynamic>.from(next!['postComments']);
                        final prevEdges = (prevData['edges'] as List?) ?? [];
                        final nextEdges = (nextData['edges'] as List?) ?? [];
                        merged['postComments'] = {
                          ...nextData,
                          'edges': [...prevEdges, ...nextEdges],
                        };
                        return merged;
                      },
                    ));
                  },
                  child: const Text('Load more comments'),
                ),
              ),
          ],
        );
      },
    );
  }
}
