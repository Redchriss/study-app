import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import '../widgets/post_card.dart';

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
      drawer: const _CommunityDrawer(),
      body: _layoutLoaded
          ? Column(
              children: [
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

class _CommunityDrawer extends StatelessWidget {
  const _CommunityDrawer();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('My Communities',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  // Unread notification indicator
                  Query(
                    options: QueryOptions(
                      document: gql(kNotifications),
                      variables: const {'limit': 1},
                      fetchPolicy: FetchPolicy.networkOnly,
                    ),
                    builder: (result, {refetch, fetchMore}) {
                      final unreadCount =
                          result.data?['unreadNotificationCount'] as num? ?? 0;
                      if (unreadCount > 0) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
            Divider(
                color: dark ? DesignTokens.darkBorder : DesignTokens.border),
            Expanded(
              child: Query(
                options: QueryOptions(document: gql(kMyCommunities)),
                builder: (result, {refetch, fetchMore}) {
                  final communities =
                      (result.data?['myCommunities'] as List?) ?? [];
                  if (result.isLoading) {
                    return const Center(child: LoadingWidget());
                  }
                  if (communities.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No communities yet',
                          style: TextStyle(color: DesignTokens.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    itemCount: communities.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return ListTile(
                          leading: const Icon(Icons.explore_outlined),
                          title: const Text('Discover'),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/discover');
                          },
                        );
                      }
                      final c = communities[i - 1] as Map<String, dynamic>;
                      final isFav = c['isFavorite'] == true;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              DesignTokens.primary.withValues(alpha: 0.1),
                          child: c['icon'] != null &&
                                  c['icon'].toString().isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(c['icon'].toString(),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.group,
                                          size: 18,
                                          color: DesignTokens.primary)),
                                )
                              : const Icon(Icons.group,
                                  size: 18, color: DesignTokens.primary),
                        ),
                        title: Text('y/${c['name']}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: isFav
                            ? const Icon(Icons.star,
                                size: 16, color: DesignTokens.warning)
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          context.push('/y/${c['slug']}');
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_circle_outline),
              title: const Text('Create Community'),
              onTap: () {
                Navigator.pop(context);
                context.push('/create-community');
              },
            ),
          ],
        ),
      ),
    );
  }
}
