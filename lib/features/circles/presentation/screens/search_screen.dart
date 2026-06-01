import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../widgets/post_card.dart';

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

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';
  String _sort = 'relevance';
  String _timeFilter = 'all';

  static const _sorts = ['relevance', 'hot', 'new', 'top', 'comments'];
  static const _sortLabels = {
    'relevance': 'Relevance',
    'hot': 'Hot',
    'new': 'New',
    'top': 'Top',
    'comments': 'Comments',
  };
  static const _timeFilters = [
    'all',
    'hour',
    'day',
    'week',
    'month',
    'year'
  ];
  static const _timeLabels = {
    'all': 'All time',
    'hour': 'Past hour',
    'day': 'Today',
    'week': 'This week',
    'month': 'This month',
    'year': 'This year',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _ctrl.text = widget.initialQuery!;
      _query = widget.initialQuery!;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark =
        Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: widget.communitySlug != null
                ? 'Search y/${widget.communitySlug}...'
                : 'Search posts...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: dark
                  ? DesignTokens.darkTextTertiary
                  : DesignTokens.textTertiary,
            ),
          ),
          onSubmitted: (q) =>
              setState(() => _query = q.trim()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () =>
                setState(() => _query = _ctrl.text.trim()),
          ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 48,
                      color: DesignTokens.textTertiary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.communitySlug != null
                          ? 'Search in y/${widget.communitySlug}'
                          : 'Type a query to search',
                      style: const TextStyle(
                          color: DesignTokens.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: dark
                            ? DesignTokens.darkBorder
                            : DesignTokens.border,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        ..._sorts.map((s) {
                          final sel = _sort == s;
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: 4),
                            child: ChoiceChip(
                              label: Text(
                                _sortLabels[s]!,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: sel
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                              selected: sel,
                              onSelected: (_) =>
                                  setState(() => _sort = s),
                              visualDensity:
                                  VisualDensity.compact,
                            ),
                          );
                        }),
                        Container(
                          width: 1,
                          height: 20,
                          margin:
                              const EdgeInsets.symmetric(horizontal: 8),
                          color: dark
                              ? DesignTokens.darkBorder
                              : DesignTokens.border,
                        ),
                        ..._timeFilters.map((t) {
                          final sel = _timeFilter == t;
                          return Padding(
                            padding:
                                const EdgeInsets.only(right: 4),
                            child: FilterChip(
                              label: Text(
                                _timeLabels[t]!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: sel
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              selected: sel,
                              onSelected: (_) => setState(
                                  () => _timeFilter = t),
                              visualDensity:
                                  VisualDensity.compact,
                              showCheckmark: false,
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Query(
                    key: ValueKey(
                        'search_$_query$_sort$_timeFilter'),
                    options: QueryOptions(
                      document: gql(kSearchPosts),
                      variables: {
                        'query': _query,
                        'sort': _sort.toUpperCase(),
                        if (widget.communitySlug != null)
                          'communitySlug': widget.communitySlug,
                        if (_timeFilter != 'all')
                          'timeFilter':
                              _timeFilter.toUpperCase(),
                        'limit': 25,
                      },
                      fetchPolicy: FetchPolicy.networkOnly,
                    ),
                    builder: (result, {fetchMore, refetch}) {
                      if (result.isLoading) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Column(children: [
                            ShimmerBox(
                                height: 100, radius: 12),
                            SizedBox(height: 8),
                            ShimmerBox(
                                height: 100, radius: 12),
                          ]),
                        );
                      }
                      if (result.hasException) {
                        return ErrorState(
                          message: 'Search failed',
                          onRetry: () => refetch?.call(),
                        );
                      }
                      final data =
                          result.data?['searchPosts'];
                      final edges =
                          (data?['edges'] as List?) ?? [];
                      final posts = edges
                          .map((e) =>
                              e['node'] as Map<String, dynamic>)
                          .toList();

                      if (posts.isEmpty) {
                        return Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(32),
                            child: Text(
                              'No results for "$_query"',
                              style: const TextStyle(
                                  color: DesignTokens
                                      .textSecondary),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: posts.length,
                        itemBuilder: (_, i) => PostCard(
                          post: posts[i],
                          layout: PostCardLayout.compact,
                          onTap: () {
                            final c = posts[i]['community']
                                as Map<String, dynamic>?;
                            if (c != null) {
                              context.push(
                                '/y/${c['slug']}/post/${posts[i]['slug']}',
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
