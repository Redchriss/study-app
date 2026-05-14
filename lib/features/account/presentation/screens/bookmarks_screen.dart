import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Bookmarked Materials', style: theme.textTheme.titleLarge)),
      body: Query(
        options: QueryOptions(document: gql(kBookmarkedMaterials)),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          if (result.hasException) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load bookmarks.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final items = (result.data?['bookmarkedMaterials'] as List?) ?? [];
          if (items.isEmpty) {
            return Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.bookmark_border, size: 64, color: DesignTokens.textTertiary),
                const SizedBox(height: 16),
                const Text('No bookmarks yet', style: TextStyle(color: DesignTokens.textTertiary)),
                const SizedBox(height: 8),
                ElevatedButton(onPressed: () => context.go('/materials'), child: const Text('Browse materials')),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final m = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: DesignTokens.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.bookmark, color: DesignTokens.warning, size: 20),
                  ),
                  title: Text(m['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Text(m['contentType'] ?? '', style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/materials/${m['slug']}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
