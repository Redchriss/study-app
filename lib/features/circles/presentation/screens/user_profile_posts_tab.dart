import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/post_card.dart';

const String kUserPosts = r'''query UserPosts { __typename }''';

class UserProfilePostsTab extends StatelessWidget {
  final String username;
  final bool fullPage;

  const UserProfilePostsTab({
    super.key,
    required this.username,
    this.fullPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kUserPosts),
        variables: {'username': username, 'sort': 'new', 'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 100, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 100, radius: 12),
            ]),
          );
        }

        final data = result.data?['userPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final posts =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No posts yet',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: NotificationListener<ScrollNotification>(
            onNotification: (scroll) {
              if (scroll is ScrollEndNotification &&
                  scroll.metrics.pixels >=
                      scroll.metrics.maxScrollExtent - 200) {
                final pageInfo = data?['pageInfo'];
                if (pageInfo?['hasNextPage'] == true) {
                  fetchMore?.call(FetchMoreOptions(
                    variables: {'after': pageInfo['endCursor']},
                    updateQuery: (prev, next) {
                      if (next?['userPosts'] == null) return prev;
                      final merged = Map<String, dynamic>.from(prev ?? {});
                      final prevData =
                          Map<String, dynamic>.from(prev?['userPosts'] ?? {});
                      final nextData =
                          Map<String, dynamic>.from(next!['userPosts']);
                      final prevEdges = (prevData['edges'] as List?) ?? [];
                      final nextEdges = (nextData['edges'] as List?) ?? [];
                      merged['userPosts'] = {
                        ...nextData,
                        'edges': [...prevEdges, ...nextEdges],
                      };
                      return merged;
                    },
                  ));
                }
              }
              return false;
            },
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 16),
              itemCount: posts.length,
              itemBuilder: (_, i) => PostCard(
                post: posts[i],
                layout: PostCardLayout.compact,
                onTap: () {
                  final c = posts[i]['community'];
                  if (c != null) {
                    context.push('/y/${c['slug']}/post/${posts[i]['slug']}');
                  }
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
