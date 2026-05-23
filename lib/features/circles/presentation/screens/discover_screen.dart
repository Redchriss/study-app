import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

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
                    itemBuilder: (_, i) => _TrendingCard(
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
                  children: communities.map((c) => _SuggestionCard(
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

class _TrendingCard extends StatelessWidget {
  final Map<String, dynamic> community;
  final bool dark;
  const _TrendingCard({required this.community, required this.dark});

  @override
  Widget build(BuildContext context) {
    final name = community['name']?.toString() ?? '';
    final displayName = community['displayName']?.toString() ?? name;
    final description = community['description']?.toString() ?? '';
    final memberCount = (community['memberCount'] as num?)?.toInt() ?? 0;
    final icon = community['icon']?.toString() ?? '';

    return GestureDetector(
      onTap: () => context.push('/y/$name'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: DesignTokens.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                  backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
                  child: icon.isEmpty
                      ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w700))
                      : null,
                ),
                const Spacer(),
                Text('y/$name',
                    style: TextStyle(fontSize: 10, color: DesignTokens.primary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(displayName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            if (description.isNotEmpty)
              Text(description,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: DesignTokens.textSecondary)),
            const Spacer(),
            Text('${_formatCount(memberCount)} members',
                style: TextStyle(fontSize: 10, color: DesignTokens.textTertiary)),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _SuggestionCard extends StatefulWidget {
  final Map<String, dynamic> community;
  const _SuggestionCard({required this.community});

  @override
  State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = widget.community;
    final name = c['name']?.toString() ?? '';
    final displayName = c['displayName']?.toString() ?? name;
    final memberCount = (c['memberCount'] as num?)?.toInt() ?? 0;
    final description = c['description']?.toString() ?? '';
    final icon = c['icon']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DesignTokens.border.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
            backgroundImage: icon.isNotEmpty ? NetworkImage(icon) : null,
            child: icon.isEmpty
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.w700))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('y/$name • ${_formatCount(memberCount)} members',
                    style: TextStyle(fontSize: 11, color: DesignTokens.textTertiary)),
                if (description.isNotEmpty)
                  Text(description,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: DesignTokens.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Mutation(
            options: MutationOptions(document: gql(kJoinCommunity)),
            builder: (run, result) {
              return SizedBox(
                height: 32,
                child: OutlinedButton(
                  onPressed: _joining ? null : () {
                    setState(() => _joining = true);
                    run({'slug': name});
                  },
                  child: _joining
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Join', style: TextStyle(fontSize: 12)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
