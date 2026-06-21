import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';

class ProfileSavedTab extends StatelessWidget {
  const ProfileSavedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
          return const EmptyState(
            icon: Icons.bookmark_outline_rounded,
            title: 'No saved posts',
            subtitle: 'Save posts from communities to find them here.',
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
                      if (next?['savedPosts'] == null) return prev;
                      final merged = Map<String, dynamic>.from(prev ?? {});
                      final prevData =
                          Map<String, dynamic>.from(prev?['savedPosts'] ?? {});
                      final nextData =
                          Map<String, dynamic>.from(next!['savedPosts']);
                      final prevEdges = (prevData['edges'] as List?) ?? [];
                      final nextEdges = (nextData['edges'] as List?) ?? [];
                      merged['savedPosts'] = {
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
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
              itemCount: posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (_, i) {
                final p = posts[i];
                final rawCommunity = p['community'];
                final community = rawCommunity is Map
                    ? Map<String, dynamic>.from(rawCommunity)
                    : null;
                final communitySlug =
                    community?['slug']?.toString() ?? '';
                final postSlug = p['slug']?.toString() ?? '';
                return InkWell(
                  onTap: communitySlug.isNotEmpty && postSlug.isNotEmpty
                      ? () => context.push(
                          '/y/$communitySlug/post/$postSlug')
                      : null,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark
                          ? DesignTokens.darkSurface
                          : DesignTokens.surface,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusMd),
                      border: Border.all(
                          color: (dark
                                  ? DesignTokens.darkBorder
                                  : DesignTokens.border)
                              .withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: [
                              const Icon(Icons.arrow_upward_rounded,
                                  size: 14,
                                  color: DesignTokens.textTertiary),
                              Text(
                                  '${(p['fuzzedScore'] as num?)?.toInt() ?? 0}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: DesignTokens.textSecondary)),
                              const Icon(Icons.arrow_downward_rounded,
                                  size: 14,
                                  color: DesignTokens.textTertiary),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                  p['title']?.toString() ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (community != null) ...[
                                    Text(
                                        'y/${community['slug'] ?? ''}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: DesignTokens.primary)),
                                    const SizedBox(width: 6),
                                  ],
                                  Icon(Icons.chat_bubble_outline,
                                      size: 12,
                                      color: DesignTokens.textTertiary),
                                  const SizedBox(width: 2),
                                  Text(
                                      '${(p['commentCount'] as num?)?.toInt() ?? 0}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: DesignTokens.textTertiary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.bookmark_rounded,
                            size: 18, color: DesignTokens.primary),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
