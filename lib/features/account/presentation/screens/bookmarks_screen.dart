import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(title: Text('Bookmarked Materials', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
      body: Query(
        options: QueryOptions(document: gql(kBookmarkedMaterials)),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          if (result.hasException) {
            return ErrorState(
              message: result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load bookmarks.',
              onRetry: () => refetch?.call(),
            );
          }
          final items = (result.data?['bookmarkedMaterials'] as List?) ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, 
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: DesignTokens.warning.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_border_rounded, size: 64, color: DesignTokens.warning),
                  ),
                  const SizedBox(height: 24),
                  Text('No bookmarks yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'Save materials you want to study later.', 
                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => context.go('/materials'), 
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('Browse materials'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spLg),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final m = items[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnimatedPress(
                    onTap: () => context.push('/materials/${m['slug']}'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: dark ? DesignTokens.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: DesignTokens.warning.withValues(alpha: 0.2)),
                        boxShadow: DesignTokens.shadowSm(dark),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48, 
                            height: 48,
                            decoration: BoxDecoration(
                              color: DesignTokens.warning.withValues(alpha: 0.12), 
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.bookmark_rounded, color: DesignTokens.warning, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['title'] ?? '', 
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, height: 1.3),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: DesignTokens.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    (m['contentType'] ?? '').toString().toUpperCase(), 
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: DesignTokens.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.chevron_right_rounded, color: DesignTokens.textTertiary),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
