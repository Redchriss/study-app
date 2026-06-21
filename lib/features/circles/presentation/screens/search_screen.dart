import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/post_card.dart';
import 'search_filter_bar.dart';

class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  final String? communitySlug;
  const SearchScreen({
    super.key,
    this.initialQuery,
    this.communitySlug,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _ctrl = TextEditingController();
  String _query = '';
  String _sort = 'relevance';
  String _timeFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          HapticService.selection();
          setState(() {});
        }
      });
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
      _query = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _runSearch() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    HapticService.lightTap();
    setState(() => _query = q);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.communitySlug != null
                ? 'Search y/${widget.communitySlug}...'
                : 'Search posts, communities, people...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: dark
                  ? DesignTokens.darkTextTertiary
                  : DesignTokens.textTertiary,
              fontSize: 15,
            ),
          ),
          onSubmitted: (_) => _runSearch(),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: _runSearch,
          ),
        ],
        bottom: _query.isEmpty
            ? null
            : TabBar(
                controller: _tabCtrl,
                tabs: const [
                  Tab(text: 'Posts'),
                  Tab(text: 'Communities'),
                  Tab(text: 'People'),
                ],
                labelColor: DesignTokens.primary,
                unselectedLabelColor: DesignTokens.textTertiary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                dividerColor: Colors.transparent,
              ),
      ),
      body: _query.isEmpty
          ? _EmptySearchHint(
              communitySlug: widget.communitySlug,
            )
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _PostsTab(
                  query: _query,
                  sort: _sort,
                  timeFilter: _timeFilter,
                  communitySlug: widget.communitySlug,
                  dark: dark,
                  onSortChanged: (s) => setState(() => _sort = s),
                  onTimeFilterChanged: (t) => setState(() => _timeFilter = t),
                ),
                _CommunitiesTab(query: _query, dark: dark),
                _PeopleTab(query: _query, dark: dark),
              ],
            ),
    );
  }
}

class _EmptySearchHint extends StatelessWidget {
  final String? communitySlug;
  const _EmptySearchHint({this.communitySlug});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_rounded,
                  size: 40, color: DesignTokens.textTertiary),
            ),
            const SizedBox(height: 16),
            Text(
              communitySlug != null
                  ? 'Search in y/$communitySlug'
                  : 'Search everything on Yaza',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Find posts, communities, and people',
              style: const TextStyle(color: DesignTokens.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Posts Tab ────────────────────────────────────────────────────────

class _PostsTab extends StatelessWidget {
  final String query;
  final String sort;
  final String timeFilter;
  final String? communitySlug;
  final bool dark;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onTimeFilterChanged;

  const _PostsTab({
    required this.query,
    required this.sort,
    required this.timeFilter,
    required this.communitySlug,
    required this.dark,
    required this.onSortChanged,
    required this.onTimeFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchFilterBar(
          sort: sort,
          timeFilter: timeFilter,
          dark: dark,
          onSortChanged: onSortChanged,
          onTimeFilterChanged: onTimeFilterChanged,
        ),
        Expanded(
          child: Query(
            key: ValueKey('search_posts_$query$sort$timeFilter'),
            options: QueryOptions(
              document: gql(kSearchPosts),
              variables: {
                'query': query,
                'sort': sort.toUpperCase(),
                if (communitySlug != null) 'communitySlug': communitySlug,
                if (timeFilter != 'all') 'timeFilter': timeFilter.toUpperCase(),
                'limit': 25,
              },
              fetchPolicy: FetchPolicy.networkOnly,
            ),
            builder: (result, {fetchMore, refetch}) {
              if (result.isLoading) {
                return const Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(children: [
                    ShimmerBox(height: 100, radius: 12),
                    SizedBox(height: 8),
                    ShimmerBox(height: 100, radius: 12),
                  ]),
                );
              }
              if (result.hasException) {
                return ErrorState(
                  message: 'Search failed',
                  onRetry: () => refetch?.call(),
                );
              }
              final data = result.data?['searchPosts'];
              final edges = (data?['edges'] as List?) ?? [];
              final posts = edges
                  .map((e) => e['node'] as Map<String, dynamic>)
                  .toList();

              if (posts.isEmpty) {
                return _NoResults(query: query);
              }

              return RefreshIndicator(
                onRefresh: () async => refetch?.call(),
                child: ListView.builder(
                  itemCount: posts.length,
                  itemBuilder: (_, i) => PostCard(
                    post: posts[i],
                    layout: PostCardLayout.compact,
                    onTap: () {
                      final c = posts[i]['community'] as Map<String, dynamic>?;
                      if (c != null) {
                        context.push('/y/${c['slug']}/post/${posts[i]['slug']}');
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Communities Tab ──────────────────────────────────────────────────

class _CommunitiesTab extends StatelessWidget {
  final String query;
  final bool dark;
  const _CommunitiesTab({required this.query, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Query(
      key: ValueKey('search_communities_$query'),
      options: QueryOptions(
        document: gql(kSearch),
        variables: {'query': query, 'type': 'COMMUNITIES', 'limit': 20},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 80, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 80, radius: 12),
            ]),
          );
        }
        if (result.hasException) {
          return ErrorState(
            message: 'Search failed',
            onRetry: () => refetch?.call(),
          );
        }
        final communities =
            (result.data?['search']?['communities'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];

        if (communities.isEmpty) return _NoResults(query: query);

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: communities.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = communities[i];
              final memberCount = (c['memberCount'] as num?)?.toInt() ?? 0;
              final icon = c['icon']?.toString() ?? '';
              return _CommunityResultCard(
                community: c,
                memberCount: memberCount,
                iconUrl: icon,
                dark: dark,
              );
            },
          ),
        );
      },
    );
  }
}

class _CommunityResultCard extends StatelessWidget {
  final Map<String, dynamic> community;
  final int memberCount;
  final String iconUrl;
  final bool dark;

  const _CommunityResultCard({
    required this.community,
    required this.memberCount,
    required this.iconUrl,
    required this.dark,
  });

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/y/${community['slug']}'),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
              color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                  .withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor:
                  DesignTokens.primary.withValues(alpha: 0.1),
              backgroundImage:
                  iconUrl.isNotEmpty ? NetworkImage(iconUrl) : null,
              child: iconUrl.isNotEmpty
                  ? null
                  : Text(community['name']?.toString()[0].toUpperCase() ?? 'Y',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: DesignTokens.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('y/${community['name']}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (community['displayName'] != null)
                    Text(community['displayName'].toString(),
                        style: const TextStyle(
                            fontSize: 12,
                            color: DesignTokens.textSecondary)),
                  const SizedBox(height: 4),
                  Text('${_formatCount(memberCount)} members',
                      style: const TextStyle(
                          fontSize: 11,
                          color: DesignTokens.textTertiary)),
                ],
              ),
            ),
            if (community['description'] != null &&
                community['description'].toString().isNotEmpty)
              Flexible(
                child: Text(
                  community['description'].toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: DesignTokens.textTertiary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── People Tab ───────────────────────────────────────────────────────

class _PeopleTab extends StatelessWidget {
  final String query;
  final bool dark;
  const _PeopleTab({required this.query, required this.dark});

  @override
  Widget build(BuildContext context) {
    return Query(
      key: ValueKey('search_people_$query'),
      options: QueryOptions(
        document: gql(kSearch),
        variables: {'query': query, 'type': 'USERS', 'limit': 20},
        fetchPolicy: FetchPolicy.networkOnly,
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Column(children: [
              ShimmerBox(height: 70, radius: 12),
              SizedBox(height: 8),
              ShimmerBox(height: 70, radius: 12),
            ]),
          );
        }
        if (result.hasException) {
          return ErrorState(
            message: 'Search failed',
            onRetry: () => refetch?.call(),
          );
        }
        final users =
            (result.data?['search']?['users'] as List?)
                    ?.cast<Map<String, dynamic>>() ??
                [];

        if (users.isEmpty) return _NoResults(query: query);

        return RefreshIndicator(
          onRefresh: () async => refetch?.call(),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final u = users[i];
              final user = u['user'] as Map<String, dynamic>?;
              final username = user?['username']?.toString() ?? '';
              final avatarUrl = u['avatarUrl']?.toString() ?? '';
              final totalKarma = (u['totalKarma'] as num?)?.toInt() ?? 0;
              return InkWell(
                onTap: () => context.push('/u/$username'),
                borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(
                        color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                            .withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            DesignTokens.accent.withValues(alpha: 0.1),
                        backgroundImage: avatarUrl.isNotEmpty
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: avatarUrl.isNotEmpty
                            ? null
                            : Text(username[0].toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: DesignTokens.accent)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('u/$username',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('$totalKarma karma',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: DesignTokens.textTertiary)),
                          ],
                        ),
                      ),
                      if (u['bio'] != null &&
                          u['bio'].toString().isNotEmpty)
                        Flexible(
                          child: Text(
                            u['bio'].toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textTertiary),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Shared ───────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: DesignTokens.textTertiary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No results for "$query"',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Try different keywords or check your spelling.',
                style: TextStyle(
                    color: DesignTokens.textSecondary, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
