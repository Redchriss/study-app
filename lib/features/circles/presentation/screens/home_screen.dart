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
import 'feed_loading.dart';
import 'home_search_bar.dart';

final _tabs = ['Best', 'Hot', 'New', 'Rising', 'Popular'];
final _tabSorts = ['best', 'hot', 'new', 'rising', 'popular'];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  int _tab = 0;
  PostCardLayout _layout = PostCardLayout.card;
  bool _layoutLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (_tabCtrl.indexIsChanging) return;
        setState(() => _tab = _tabCtrl.index);
      });
    _loadLayout();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
    return Scaffold(
      drawer: const CommunityDrawer(),
      body: !_layoutLoaded
          ? const Center(child: LoadingWidget())
          : SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // ── Top bar: no AppBar, search bar like Reddit ──────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
                    child: Row(
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu_rounded),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        const HomeSearchBar(),
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
                          icon: const Icon(Icons.explore_outlined),
                          tooltip: 'Discover',
                          onPressed: () => context.push('/home/discover'),
                        ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabCtrl,
                    tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: DesignTokens.primary,
                    unselectedLabelColor: DesignTokens.textSecondary,
                    dividerColor: Colors.transparent,
                  ),
                  Expanded(
                    child: Query(
                      key: ValueKey('home_$_tab'),
                      options: QueryOptions(
                        document: gql(_tab == 4 ? kPopularPosts : kHomeFeed),
                        variables: _tab == 4
                            ? {'limit': 25}
                            : {'sort': _tabSorts[_tab], 'limit': 25},
                        fetchPolicy: FetchPolicy.networkOnly,
                      ),
                      builder: (result, {fetchMore, refetch}) {
                        if (result.isLoading) return const FeedLoading();
                        if (result.hasException) {
                          return ErrorState(
                            message: graphQLErrorMessage(
                                result.exception, 'Could not load feed'),
                            onRetry: () => refetch?.call(),
                          );
                        }

                        final feedKey = _tab == 4 ? 'popularPosts' : 'homeFeed';
                        final feed = result.data?[feedKey];
                        final edges = (feed?['edges'] as List?) ?? [];
                        final posts = edges
                            .map((e) => e['node'] as Map<String, dynamic>)
                            .toList();

                        if (posts.isEmpty) {
                          return EmptyState(
                            icon: Icons.group_outlined,
                            title: _tab == 4
                                ? 'Nothing trending yet'
                                : 'Join some communities',
                            subtitle: _tab == 4
                                ? 'Check back soon for popular posts.'
                                : 'Your feed is empty. Discover communities to follow.',
                            actionLabel: 'Discover',
                            onAction: () => context.push('/home/discover'),
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
                                      if (next?[feedKey] == null) return prev;
                                      final merged =
                                          Map<String, dynamic>.from(prev ?? {});
                                      final prevFeed =
                                          Map<String, dynamic>.from(
                                              prev?[feedKey] ?? {});
                                      final nextFeed =
                                          Map<String, dynamic>.from(
                                              next![feedKey]);
                                      merged[feedKey] = {
                                        ...nextFeed,
                                        'edges': [
                                          ...((prevFeed['edges'] as List?) ??
                                              []),
                                          ...((nextFeed['edges'] as List?) ??
                                              []),
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
                              padding:
                                  const EdgeInsets.only(top: 4, bottom: 80),
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
              ),
            ),
    );
  }
}
