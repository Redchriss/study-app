import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../widgets/post_card.dart';

class CommunityPostList extends StatelessWidget {
  final String slug;
  final String sort;
  final bool isMember;
  final String? postType;
  final String? flairId;

  const CommunityPostList({
    super.key,
    required this.slug,
    required this.sort,
    required this.isMember,
    this.postType,
    this.flairId,
  });

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityPosts),
        variables: {
          'slug': slug,
          'sort': sort,
          'limit': 25,
          if (postType != null) 'postType': postType,
          if (flairId != null) 'flairId': flairId,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 130, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 130, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 130, radius: 12),
            ]),
          );
        }
        if (result.hasException) {
          return ErrorState(
            message:
                graphQLErrorMessage(result.exception, 'Could not load posts'),
            onRetry: () => refetch?.call(),
          );
        }

        final data = result.data?['communityPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final posts =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();

        if (posts.isEmpty) {
          return EmptyState(
            icon: Icons.article_outlined,
            title: 'No posts yet',
            subtitle:
                isMember ? 'Be the first to post!' : 'Join to participate.',
            actionLabel: isMember ? 'Create Post' : null,
            onAction: isMember ? () => context.push('/y/$slug/submit') : null,
          );
        }

        return Column(
          children: [
            ...posts.map((p) => PostCard(
                  post: p,
                  onTap: () => context.push('/y/$slug/post/${p['slug']}'),
                )),
            if (data?['pageInfo']?['hasNextPage'] == true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: () {
                    fetchMore?.call(FetchMoreOptions(
                      variables: {'after': data['pageInfo']['endCursor']},
                      updateQuery: (prev, next) {
                        if (next?['communityPosts'] == null) return prev;
                        final merged = Map<String, dynamic>.from(prev ?? {});
                        final prevData = Map<String, dynamic>.from(
                            prev?['communityPosts'] ?? {});
                        final nextData =
                            Map<String, dynamic>.from(next!['communityPosts']);
                        final prevEdges = (prevData['edges'] as List?) ?? [];
                        final nextEdges = (nextData['edges'] as List?) ?? [];
                        merged['communityPosts'] = {
                          ...nextData,
                          'edges': [...prevEdges, ...nextEdges],
                        };
                        return merged;
                      },
                    ));
                  },
                  child: const Text('Load more'),
                ),
              ),
          ],
        );
      },
    );
  }
}
