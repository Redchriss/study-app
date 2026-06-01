import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'community_card_widget.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'All';

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
        title: Text('Discover',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: dark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.surfaceVariant,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Create Community',
                  onPressed: () => context.push('/create-community'),
                ),
              ),
              onSubmitted: (q) {
                if (q.trim().isNotEmpty) {
                  context.push('/search?q=${Uri.encodeComponent(q.trim())}');
                }
              },
            ),
            const SizedBox(height: 12),
            _buildTrendingSection(dark),
            const SizedBox(height: 24),
            Text('New & Growing',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _buildNewGrowingSection(),
            const SizedBox(height: 24),
            Text('Suggested for You',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _buildSuggestedSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(bool dark) {
    final searchParam = _selectedCategory == 'All' ? null : _selectedCategory;
    return Query(
      options: QueryOptions(
        document: gql(kTrendingCommunities),
        variables: {'limit': 10},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Row(
            children: [
              ShimmerBox(width: 140, height: 130, radius: 12),
              SizedBox(width: 8),
              ShimmerBox(width: 140, height: 130, radius: 12),
            ],
          );
        }
        List communities = (result.data?['trendingCommunities'] as List?) ?? [];
        if (searchParam != null) {
          communities = communities
              .where((c) =>
                  (c['displayName']?.toString() ?? '')
                      .toLowerCase()
                      .contains(searchParam.toLowerCase()) ||
                  (c['name']?.toString() ?? '')
                      .toLowerCase()
                      .contains(searchParam.toLowerCase()) ||
                  (c['description']?.toString() ?? '')
                      .toLowerCase()
                      .contains(searchParam.toLowerCase()))
              .toList();
        }
        if (communities.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: communities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => CommunityCardWidget(
              community: communities[i] as Map<String, dynamic>,
              compact: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewGrowingSection() {
    return Query(
      options: QueryOptions(
        document: gql(kCommunities),
        variables: {
          'sort': 'new',
          'limit': 10,
        },
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Row(
            children: [
              ShimmerBox(width: 140, height: 130, radius: 12),
              SizedBox(width: 8),
              ShimmerBox(width: 140, height: 130, radius: 12),
            ],
          );
        }
        final communities = (result.data?['communities'] as List?) ?? [];
        if (communities.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: communities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => CommunityCardWidget(
              community: communities[i] as Map<String, dynamic>,
              compact: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSuggestedSection() {
    return Query(
      options: QueryOptions(
        document: gql(kSuggestedCommunities),
        variables: {'limit': 20},
        fetchPolicy: FetchPolicy.networkOnly,
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
        final communities =
            (result.data?['suggestedCommunities'] as List?) ?? [];
        if (communities.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('No suggestions yet',
                  style: TextStyle(color: DesignTokens.textSecondary)),
            ),
          );
        }
        return Column(
          children: communities
              .map((c) =>
                  CommunityCardWidget(community: c as Map<String, dynamic>))
              .toList(),
        );
      },
    );
  }
}
