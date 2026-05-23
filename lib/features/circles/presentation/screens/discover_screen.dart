import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'discover_trending_card.dart';
import 'discover_suggestion_card.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Discover', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search communities...',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant,
              ),
              onSubmitted: (q) {
                if (q.trim().isNotEmpty) {
                  context.push('/search?q=${Uri.encodeComponent(q.trim())}');
                }
              },
            ),
            const SizedBox(height: 24),
            Text('Trending',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Query(
              options: QueryOptions(
                document: gql(kTrendingCommunities),
                variables: {'limit': 10},
              ),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) {
                  return const Row(
                    children: [
                      ShimmerBox(width: 140, height: 120, radius: 12),
                      SizedBox(width: 8),
                      ShimmerBox(width: 140, height: 120, radius: 12),
                    ],
                  );
                }
                final communities = (result.data?['trendingCommunities'] as List?) ?? [];
                if (communities.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 130,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: communities.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => DiscoverTrendingCard(
                      community: communities[i] as Map<String, dynamic>,
                      dark: dark,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text('Suggested for You',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Query(
              options: QueryOptions(
                document: gql(kSuggestedCommunities),
                variables: {'limit': 20},
              ),
              builder: (result, {fetchMore, refetch}) {
                if (result.isLoading) {
                  return const Column(
                    children: [
                      ShimmerBox(height: 80, radius: 12),
                      SizedBox(height: 8),
                      ShimmerBox(height: 80, radius: 12),
                    ],
                  );
                }
                final communities = (result.data?['suggestedCommunities'] as List?) ?? [];
                if (communities.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No suggestions yet',
                          style: TextStyle(color: DesignTokens.textSecondary)),
                    ),
                  );
                }
                return Column(
                  children: communities.map((c) => DiscoverSuggestionCard(
                    community: c as Map<String, dynamic>,
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
