import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/circle_post_card.dart';

class CirclePostsList extends StatelessWidget {
  const CirclePostsList({
    super.key,
    required this.slug,
    required this.sort,
    required this.typeFilter,
    required this.solvedOnly,
    required this.onRefetch,
  });

  final String slug;
  final String sort;
  final String typeFilter;
  final bool solvedOnly;
  final VoidCallback onRefetch;

  List<Map<String, dynamic>> _filterPosts(List rawPosts) {
    return rawPosts
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((post) {
      if (typeFilter != 'all' && post['postType']?.toString() != typeFilter) {
        return false;
      }
      if (solvedOnly && post['isSolved'] != true) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCirclePosts),
        variables: {'slug': slug, 'sort': sort},
        pollInterval: const Duration(seconds: 30),
      ),
      builder: (postResult, {fetchMore, refetch}) {
        if (postResult.isLoading) {
          return const LoadingWidget();
        }
        if (postResult.hasException) {
          return ErrorState(
            message: graphQLErrorMessage(postResult.exception, 'Failed to load posts'),
            onRetry: () => refetch?.call(),
          );
        }
        final posts = _filterPosts(
            (postResult.data?['circlePosts'] as List?) ?? const []);
        if (posts.isEmpty) {
          return const Center(
              child: Text('No posts yet',
                  style: TextStyle(color: DesignTokens.textSecondary)));
        }
        return RefreshIndicator(
          onRefresh: () async {
            refetch?.call();
            onRefetch();
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd),
            itemCount: posts.length,
            itemBuilder: (_, i) {
              final p = posts[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: DesignTokens.spXs),
                child: CirclePostCard(
                  post: p,
                  onTap: () => context.push('/circles/$slug/post/${p['slug']}'),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
