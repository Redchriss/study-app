import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/vote_buttons.dart';

class UserProfileCommentsTab extends StatelessWidget {
  final String username;

  const UserProfileCommentsTab({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kUserComments),
        variables: {'username': username, 'sort': 'new', 'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 60, radius: 8),
              SizedBox(height: 8),
              ShimmerBox(height: 60, radius: 8),
            ]),
          );
        }

        final data = result.data?['userComments'];
        final edges = (data?['edges'] as List?) ?? [];
        final comments =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (comments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text('No comments yet',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            itemCount: comments.length,
            itemBuilder: (_, i) {
              final c = comments[i];
              final author = c['author'] as Map<String, dynamic>?;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: DesignTokens.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CommentVoteButtons(
                          commentId: c['id'].toString(),
                          upvotes: (c['fuzzedUpvotes'] as num?)?.toInt() ?? 0,
                          downvotes:
                              (c['fuzzedDownvotes'] as num?)?.toInt() ?? 0,
                          score: (c['fuzzedScore'] as num?)?.toInt() ?? 0,
                        ),
                        const SizedBox(width: 8),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      c['body']?.toString() ?? '',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'u/${author?['username'] ?? 'unknown'}',
                      style: TextStyle(
                          fontSize: 11, color: DesignTokens.textSecondary),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
