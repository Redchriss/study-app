import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import 'community_post_list.dart';
import 'community_header.dart';
import 'community_filter_bar.dart';
import 'community_info_section.dart';
import 'community_pinned_posts.dart';

class CommunityScreen extends StatefulWidget {
  final String slug;
  const CommunityScreen({super.key, required this.slug});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  int _sortIdx = 1;
  String _timeFilter = 'all';
  String? _postType;
  String? _flairId;
  List<Map<String, dynamic>> _flairs = [];

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

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
                child: CommunityInfoSection(
                  community: community,
                  theme: theme,
                  isMember: isMember,
                  isFav: isFav,
                  memberCount: memberCount,
                  formatCount: _formatCount,
                  slug: widget.slug,
                  onFavToggle: () {
                    refetch?.call();
                  },
                  onJoinToggle: () {
                    refetch?.call();
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: CommunityFilterBar(
                  sortIdx: _sortIdx,
                  timeFilter: _timeFilter,
                  postType: _postType,
                  flairId: _flairId,
                  flairs: _flairs,
                  onSortChanged: (i) => setState(() => _sortIdx = i),
                  onTimeFilterChanged: (f) => setState(() => _timeFilter = f),
                  onPostTypeChanged: (t) => setState(() => _postType = t),
                  onFlairChanged: (f) => setState(() => _flairId = f),
                ),
              ),
              SliverToBoxAdapter(
                child: PinnedPostsSection(
                  slug: widget.slug,
                  isMember: isMember,
                ),
              ),
              SliverToBoxAdapter(
                child: CommunityPostList(
                  key: ValueKey(
                      'posts_${widget.slug}_$_sortIdx$_timeFilter$_postType$_flairId'),
                  slug: widget.slug,
                  sort: postSorts[_sortIdx],
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
}
