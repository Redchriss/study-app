import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';

class SavedTab extends StatelessWidget {
  const SavedTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kSavedPosts),
        variables: const {'limit': 25},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (QueryResult result,
          {VoidCallback? refetch, FetchMore? fetchMore}) {
        if (result.isLoading) return const Center(child: LoadingWidget());
        if (result.hasException) {
          return ErrorState(
            message:
                graphQLErrorMessage(result.exception, 'Could not load saved'),
            onRetry: () => refetch?.call(),
          );
        }
        final data = result.data?['savedPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final posts =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('No saved posts',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (_, i) => ListTile(
            leading: const Icon(Icons.bookmark, size: 20),
            title: Text(posts[i]['title']?.toString() ?? '',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(
                'y/${(posts[i]['community'] as Map?)?['name'] ?? ''}',
                style: const TextStyle(fontSize: 12)),
          ),
        );
      },
    );
  }
}
