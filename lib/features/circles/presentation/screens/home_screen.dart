import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../widgets/post_card.dart';
import 'home_drawer.dart';

final _tabs = ['Best', 'Hot', 'New', 'Rising'];
final _tabSorts = ['best', 'hot', 'new', 'rising'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  PostCardLayout _layout = PostCardLayout.card;
  bool _layoutLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadLayout();
  }

  Future<void> _loadLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('post_card_layout');
    if (saved != null && mounted) {
      setState(() {
        _layout = PostCardLayout.values.firstWhere(
          (l) => l.name == saved,
          orElse: () => PostCardLayout.card,
        );
        _layoutLoaded = true;
      });
    } else if (mounted) {
      setState(() => _layoutLoaded = true);
    }
  }

  Future<void> _saveLayout(PostCardLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('post_card_layout', layout.name);
  }

  PostCardLayout _nextLayout(PostCardLayout current) {
    switch (current) {
      case PostCardLayout.compact:
        return PostCardLayout.card;
      case PostCardLayout.card:
        return PostCardLayout.classic;
      case PostCardLayout.classic:
        return PostCardLayout.compact;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Home',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _layout == PostCardLayout.compact
                  ? Icons.view_list_rounded
                  : _layout == PostCardLayout.card
                      ? Icons.grid_view_rounded
                      : Icons.article_rounded,
            ),
            onPressed: () {
              final next = _nextLayout(_layout);
              setState(() => _layout = next);
              _saveLayout(next);
            },
          ),
          IconButton(
            icon: const Icon(Icons.dashboard_rounded),
            tooltip: 'Study Dashboard',
            onPressed: () => context.push('/dashboard'),
          ),
        ],
      ),
      drawer: const CommunityDrawer(),
      body: _layoutLoaded
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  child: TextField(
                    onTap: () => context.push('/search'),
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: 'Search posts, communities, users...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      filled: true,
                      fillColor: dark
                          ? DesignTokens.darkSurfaceVariant
                          : DesignTokens.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                  ),
                ),
                TabBar(
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                  isScrollable: false,
                  indicatorSize: TabBarIndicatorSize.label,
                  onTap: (i) => setState(() => _tab = i),
                  labelColor: DesignTokens.primary,
                  unselectedLabelColor: DesignTokens.textSecondary,
                ),
                Expanded(
                  child: Query(
                    key: ValueKey('home_$_tab'),
                    options: QueryOptions(
                      document: gql(kHomeFeed),
                      variables: {'sort': _tabSorts[_tab], 'limit': 25},
                      fetchPolicy: FetchPolicy.networkOnly,
                    ),
                    builder: (result, {fetchMore, refetch}) {
                      if (result.isLoading) return const _FeedLoading();
                      if (result.hasException) {
                        return ErrorState(
                          message: graphQLErrorMessage(
                              result.exception, 'Could not load feed'),
                          onRetry: () => refetch?.call(),
                        );
                      }

                      final feed = result.data?['homeFeed'];
                      final edges = (feed?['edges'] as List?) ?? [];
                      final posts = edges
                          .map((e) => e['node'] as Map<String, dynamic>)
                          .toList();

                      if (posts.isEmpty) {
                        return EmptyState(
                          icon: Icons.group_outlined,
                          title: 'Join some communities',
                          subtitle:
                              'Your feed is empty. Discover communities to follow.',
                          actionLabel: 'Discover',
                          onAction: () => context.push('/discover'),
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: () async => refetch?.call(),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (scroll) {
                            if (scroll is ScrollEndNotification &&
                                scroll.metrics.pixels >=
                                    scroll.metrics.maxScrollExtent - 200) {
                              final pageInfo = feed?['pageInfo'];
                              if (pageInfo?['hasNextPage'] == true) {
                                fetchMore?.call(FetchMoreOptions(
                                  variables: {'after': pageInfo['endCursor']},
                                  updateQuery: (prev, next) {
                                    if (next?['homeFeed'] == null) return prev;
                                    final merged =
                                        Map<String, dynamic>.from(prev ?? {});
                                    final prevFeed = Map<String, dynamic>.from(
                                        prev?['homeFeed'] ?? {});
                                    final nextFeed = Map<String, dynamic>.from(
                                        next!['homeFeed']);
                                    final prevEdges =
                                        (prevFeed['edges'] as List?) ?? [];
                                    final nextEdges =
                                        (nextFeed['edges'] as List?) ?? [];
                                    merged['homeFeed'] = {
                                      ...nextFeed,
                                      'edges': [
                                        ...prevEdges,
                                        ...nextEdges,
                                      ],
                                    };
                                    return merged;
                                  },
                                ));
                              }
                            }
                            return false;
                          },
                          child: ListView.builder(
                            padding: const EdgeInsets.only(top: 4, bottom: 80),
                            itemCount: posts.length,
                            itemBuilder: (_, i) => PostCard(
                              post: posts[i],
                              layout: _layout,
                              onTap: () {
                                final c = posts[i]['community'];
                                if (c != null) {
                                  context.push(
                                      '/y/${c['slug']}/post/${posts[i]['slug']}');
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            )
          : const Center(child: LoadingWidget()),
    );
  }
}

class _FeedLoading extends StatelessWidget {
  const _FeedLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: 6,
      itemBuilder: (_, __) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: ShimmerBox(height: 140, radius: DesignTokens.radiusMd),
      ),
    );
  }
}
