import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/widgets/widgets.dart';

class CirclePostSearchDelegate extends SearchDelegate {
  final String circleSlug;
  CirclePostSearchDelegate(this.circleSlug);

  @override
  List<Widget>? buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null));

  @override
  Widget buildResults(BuildContext context) => _buildSearch(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearch(context);

  Widget _buildSearch(BuildContext context) {
    if (query.isEmpty)
      return const EmptyState(icon: Icons.search, title: 'Search posts');
    return Query(
      options: QueryOptions(
          document: gql(kSearchPosts),
          variables: {'query': query, 'circleSlug': circleSlug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading)
          return const Center(child: CircularProgressIndicator());
        if (result.hasException)
          return ErrorState(
            message: result.exception?.graphqlErrors.firstOrNull?.message ??
                'Search failed',
            onRetry: () => refetch?.call(),
          );
        final posts = (result.data?['searchPosts'] as List?) ?? [];
        if (posts.isEmpty)
          return const EmptyState(icon: Icons.search_off, title: 'No results');
        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final p = posts[i] as Map<String, dynamic>;
            return ListTile(
              title: Text(p['title']?.toString() ?? ''),
              subtitle: Text(
                  '${p['author']?['username'] ?? ''}  ·  ${p['commentCount'] ?? 0} comments'),
              onTap: () {
                close(context, null);
                context.go('/circles/$circleSlug/post/${p['slug']}');
              },
            );
          },
        );
      },
    );
  }
}
