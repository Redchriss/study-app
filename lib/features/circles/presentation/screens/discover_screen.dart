import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'community_card_widget.dart';

const _categories = [
  ('All', Icons.auto_awesome_rounded, DesignTokens.primary),
  ('Academic', Icons.school_rounded, Color(0xFF1B6CA8)),
  ('Science', Icons.science_rounded, Color(0xFF27AE60)),
  ('Social', Icons.groups_rounded, Color(0xFFE87E5E)),
  ('Tech', Icons.computer_rounded, Color(0xFF7A4D9E)),
  ('Creative', Icons.palette_rounded, Color(0xFFF39C12)),
];

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchCtrl = TextEditingController();
  String _category = 'All';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List _filterByCategory(List communities) {
    if (_category == 'All') return communities;
    final cat = _category.toLowerCase();
    return communities.where((c) {
      final desc = (c['description']?.toString() ?? '').toLowerCase();
      final name = (c['name']?.toString() ?? '').toLowerCase();
      final display = (c['displayName']?.toString() ?? '').toLowerCase();
      return desc.contains(cat) || name.contains(cat) || display.contains(cat);
    }).toList();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            tooltip: 'Create Community',
            onPressed: () => context.push('/create-community'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search communities, posts, people...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor: dark
                      ? DesignTokens.darkSurfaceVariant
                      : DesignTokens.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                ),
                onSubmitted: (q) {
                  if (q.trim().isNotEmpty) {
                    context.push(
                        '/search?q=${Uri.encodeComponent(q.trim())}');
                  }
                },
                textInputAction: TextInputAction.search,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, icon, color) = _categories[i];
                  final isSelected = _category == label;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: GestureDetector(
                      onTap: () {
                        HapticService.selection();
                        setState(() => _category = label);
                      },
                      child: AnimatedContainer(
                        duration: DesignTokens.durFast,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(colors: [
                                  color, color.withValues(alpha: 0.7)])
                              : null,
                          color: isSelected ? null : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : color.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon,
                                size: 14,
                                color: isSelected ? Colors.white : color),
                            const SizedBox(width: 5),
                            Text(label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: isSelected ? Colors.white : color,
                                )),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 18, color: DesignTokens.warning),
                  const SizedBox(width: 6),
                  Text('Trending',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildTrendingSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.fiber_new_rounded,
                      size: 18, color: DesignTokens.accent),
                  const SizedBox(width: 6),
                  Text('New & Growing',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildNewGrowingSection()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded,
                      size: 18, color: DesignTokens.primary),
                  const SizedBox(width: 6),
                  Text('Suggested for You',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverToBoxAdapter(child: _buildSuggestedSection()),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingSection() {
    return Query(
      options: QueryOptions(
        document: gql(kTrendingCommunities),
        variables: {'limit': 10},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const SizedBox(
            height: 140,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: ShimmerBox(height: 130, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 130, radius: 12)),
              ]),
            ),
          );
        }
        List communities =
            (result.data?['trendingCommunities'] as List?) ?? [];
        communities = _filterByCategory(communities);
        if (communities.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
        variables: {'sort': 'new', 'limit': 10},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const SizedBox(
            height: 140,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                Expanded(child: ShimmerBox(height: 130, radius: 12)),
                SizedBox(width: 8),
                Expanded(child: ShimmerBox(height: 130, radius: 12)),
              ]),
            ),
          );
        }
        final rawEdges =
            (result.data?['communities']?['edges'] as List?) ?? [];
        List communities = rawEdges
            .map((e) => e['node'] as Map<String, dynamic>?)
            .whereType<Map<String, dynamic>>()
            .toList();
        communities = _filterByCategory(communities);
        if (communities.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
          return const Column(children: [
            ShimmerBox(height: 80, radius: 12),
            SizedBox(height: 8),
            ShimmerBox(height: 80, radius: 12),
          ]);
        }
        List communities =
            (result.data?['suggestedCommunities'] as List?) ?? [];
        communities = _filterByCategory(communities);
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
