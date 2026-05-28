import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import 'community_post_list.dart';
import 'community_header.dart';
import '../widgets/post_card.dart';

final _postSorts = ['hot', 'new', 'top', 'rising', 'controversial'];
final _timeFilters = ['all', 'hour', 'day', 'week', 'month', 'year'];
final _timeFilterLabels = {
  'all': 'All time',
  'hour': 'Past hour',
  'day': 'Today',
  'week': 'This week',
  'month': 'This month',
  'year': 'This year'
};
final _timeFilterSorts = {'top', 'controversial'};
final _postTypes = <String?>{null, 'TEXT', 'IMAGE', 'VIDEO', 'LINK', 'POLL'};
final _postTypeLabels = {
  null: 'All',
  'TEXT': 'Text',
  'IMAGE': 'Images',
  'VIDEO': 'Video',
  'LINK': 'Links',
  'POLL': 'Polls'
};

class CommunityScreen extends StatefulWidget {
  final String slug;
  const CommunityScreen({super.key, required this.slug});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _sortIdx = 0;
  String _timeFilter = 'all';
  String? _postType;
  String? _flairId;
  List<Map<String, dynamic>> _flairs = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kCommunity),
        variables: {'slug': widget.slug},
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: LoadingWidget()),
          );
        }
        if (result.hasException) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load community'),
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final community = result.data?['community'] as Map<String, dynamic>?;
        if (community == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Community not found')),
          );
        }

        final flairsData = result.data?['communityFlair'] as List? ?? [];
        _flairs = flairsData.cast<Map<String, dynamic>>();

        final isMember = community['isMember'] == true;
        final isMod = community['isModerator'] == true;
        final isFav = community['isFavorite'] == true;
        final memberCount = (community['memberCount'] as num?)?.toInt() ?? 0;

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: CommunityHeader(community: community, dark: dark),
                ),
                actions: [
                  if (isMod)
                    IconButton(
                      icon: const Icon(Icons.shield_outlined),
                      onPressed: () => context.push('/y/${widget.slug}/mod'),
                    ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('y/${community['name']}',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                            fontWeight: FontWeight.w800)),
                                const SizedBox(height: 2),
                                Text('${_formatCount(memberCount)} members',
                                    style: const TextStyle(
                                        color: DesignTokens.textSecondary,
                                        fontSize: 13)),
                              ],
                            ),
                          ),
                          Mutation(
                            options:
                                MutationOptions(document: gql(kJoinCommunity)),
                            builder: (joinRun, joinResult) {
                              return Mutation(
                                options: MutationOptions(
                                    document: gql(kToggleFavourite)),
                                builder: (favRun, favResult) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isMember)
                                        IconButton(
                                          icon: Icon(
                                            isFav
                                                ? Icons.star
                                                : Icons.star_border,
                                            color: isFav
                                                ? DesignTokens.warning
                                                : null,
                                          ),
                                          onPressed: () {
                                            favRun({'slug': widget.slug});
                                            refetch?.call();
                                          },
                                        ),
                                      const SizedBox(width: 4),
                                      FilledButton.tonal(
                                        onPressed: () {
                                          if (isMember) {
                                            showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text(
                                                    'Leave community?'),
                                                content: Text(
                                                    'Leave y/${community['name']}?'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(ctx),
                                                      child:
                                                          const Text('Cancel')),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(ctx);
                                                      context.go('/');
                                                    },
                                                    child: const Text('Leave',
                                                        style: TextStyle(
                                                            color: DesignTokens
                                                                .error)),
                                                  ),
                                                ],
                                              ),
                                            );
                                          } else {
                                            joinRun({'slug': widget.slug});
                                            refetch?.call();
                                          }
                                        },
                                        child:
                                            Text(isMember ? 'Joined' : 'Join'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                      if (community['description'] != null &&
                          community['description'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(community['description'].toString(),
                              style: const TextStyle(
                                  color: DesignTokens.textSecondary,
                                  fontSize: 13)),
                        ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _postSorts.asMap().entries.map((e) {
                      final isSelected = e.key == _sortIdx;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(e.value.toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700)),
                          selected: isSelected,
                          onSelected: (_) => setState(() {
                            _sortIdx = e.key;
                          }),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: _postTypes.map((t) {
                      final isSelected = _postType == t;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(_postTypeLabels[t]!,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600)),
                          selected: isSelected,
                          onSelected: (_) => setState(
                              () => _postType = t == _postType ? null : t),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              if (_timeFilterSorts.contains(_postSorts[_sortIdx]))
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: _timeFilters.map((t) {
                        final isSelected = _timeFilter == t;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(_timeFilterLabels[t]!,
                                style: const TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            selected: isSelected,
                            onSelected: (_) => setState(() =>
                                _timeFilter = t == _timeFilter ? 'all' : t),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (_flairs.isNotEmpty)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: const Text('All Flairs',
                                style: TextStyle(
                                    fontSize: 11, fontWeight: FontWeight.w600)),
                            selected: _flairId == null,
                            onSelected: (_) => setState(() => _flairId = null),
                          ),
                        ),
                        ..._flairs.map((f) {
                          final isSelected = _flairId == f['id'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: FilterChip(
                              label: Text(f['text']?.toString() ?? '',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _flairId =
                                  isSelected ? null : f['id']?.toString()),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: _PinnedPostsSection(
                  slug: widget.slug,
                  isMember: isMember,
                ),
              ),
              SliverToBoxAdapter(
                child: CommunityPostList(
                  key: ValueKey(
                      'posts_${widget.slug}_$_sortIdx$_timeFilter$_postType$_flairId'),
                  slug: widget.slug,
                  sort: _postSorts[_sortIdx],
                  timeFilter: _timeFilter,
                  isMember: isMember,
                  postType: _postType,
                  flairId: _flairId,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _PinnedPostsSection extends StatelessWidget {
  final String slug;
  final bool isMember;
  const _PinnedPostsSection({required this.slug, required this.isMember});

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(
        document: gql(kCommunityPosts),
        variables: {
          'slug': slug,
          'sort': 'hot',
          'isPinned': true,
          'limit': 2,
        },
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading || result.hasException) {
          return const SizedBox.shrink();
        }
        final data = result.data?['communityPosts'];
        final edges = (data?['edges'] as List?) ?? [];
        final pinned =
            edges.map((e) => e['node'] as Map<String, dynamic>).toList();
        if (pinned.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.push_pin, size: 14, color: DesignTokens.warning),
                  SizedBox(width: 4),
                  Text('PINNED',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.warning,
                        letterSpacing: 0.5,
                      )),
                ],
              ),
            ),
            ...pinned.map((p) => PostCard(
                  post: p,
                  onTap: () => context.push('/y/$slug/post/${p['slug']}'),
                )),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
