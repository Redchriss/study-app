import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';

class ProfileSavedTab extends StatelessWidget {
  const ProfileSavedTab({super.key});

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
        final posts = edges
            .whereType<Map>()
            .map((edge) => edge['node'])
            .whereType<Map>()
            .map((node) => Map<String, dynamic>.from(node))
            .toList();
        if (posts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_outline,
                      size: 48, color: DesignTokens.textTertiary),
                  SizedBox(height: 12),
                  Text('No saved posts',
                      style: TextStyle(
                          color: DesignTokens.textSecondary, fontSize: 15)),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          itemBuilder: (_, i) {
            final p = posts[i];
            final rawCommunity = p['community'];
            final community = rawCommunity is Map
                ? Map<String, dynamic>.from(rawCommunity)
                : null;
            return ListTile(
              leading: Container(
                width: 36,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    const Icon(Icons.arrow_upward,
                        size: 12, color: DesignTokens.textTertiary),
                    Text('${(p['fuzzedScore'] as num?)?.toInt() ?? 0}',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              title: Text(p['title']?.toString() ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text('y/${community?['name'] ?? ''}',
                  style: const TextStyle(fontSize: 11)),
              trailing: const Icon(Icons.bookmark,
                  size: 18, color: DesignTokens.primary),
            );
          },
        );
      },
    );
  }
}
