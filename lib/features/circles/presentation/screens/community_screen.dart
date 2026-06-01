import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import 'community_post_list.dart';
import 'community_header.dart';
import 'community_filter_bar.dart';
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
        fetchPolicy: FetchPolicy.networkOnly,
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
        final flairs = flairsData.cast<Map<String, dynamic>>();

        final isMember = community['isMember'] == true;
        final isMod = community['isModerator'] == true;
        final isFav = community['isFavorite'] == true;
        final memberCount = (community['memberCount'] as num?)?.toInt() ?? 0;

        return Scaffold(
          floatingActionButton: isMember
              ? FloatingActionButton.small(
                  onPressed: () => context.push('/y/${widget.slug}/submit'),
                  child: const Icon(Icons.add_rounded),
                )
              : null,
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverCommunityHeader(
                  community: community,
                  dark: dark,
                  isMember: isMember,
                  isFav: isFav,
                  memberCount: memberCount,
                  formatCount: _formatCount,
                  slug: widget.slug,
                  isMod: isMod,
                  onJoinChanged: () => refetch?.call(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _FilterBarDelegate(
                  child: CommunityFilterBar(
                    sortIdx: _sortIdx,
                    timeFilter: _timeFilter,
                    postType: _postType,
                    flairId: _flairId,
                    flairs: flairs,
                    onSortChanged: (i) => setState(() => _sortIdx = i),
                    onTimeFilterChanged: (f) => setState(() => _timeFilter = f),
                    onPostTypeChanged: (t) => setState(() => _postType = t),
                    onFlairChanged: (f) => setState(() => _flairId = f),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child:
                    PinnedPostsSection(slug: widget.slug, isMember: isMember),
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

class _SliverCommunityHeader extends SliverPersistentHeaderDelegate {
  final Map<String, dynamic> community;
  final bool dark;
  final bool isMember;
  final bool isFav;
  final int memberCount;
  final String Function(int) formatCount;
  final String slug;
  final bool isMod;
  final VoidCallback onJoinChanged;

  _SliverCommunityHeader({
    required this.community,
    required this.dark,
    required this.isMember,
    required this.isFav,
    required this.memberCount,
    required this.formatCount,
    required this.slug,
    required this.isMod,
    required this.onJoinChanged,
  });

  @override
  double get minExtent => 96;
  @override
  double get maxExtent => 220;
  @override
  bool shouldRebuild(_) => true;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: 1 - progress,
          child: CommunityHeader(community: community, dark: dark),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(16, 16 * (1 - progress), 16, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  dark ? DesignTokens.darkBackground : DesignTokens.background,
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'y/${community['name']}',
                              style: TextStyle(
                                fontSize: (20 * (1 - progress) + 16 * progress)
                                    .clamp(16, 20),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${formatCount(memberCount)} members',
                              style: TextStyle(
                                fontSize: 12,
                                color: dark
                                    ? DesignTokens.darkTextSecondary
                                    : DesignTokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _JoinFavButtons(
                        slug: slug,
                        isMember: isMember,
                        isFav: isFav,
                        onJoinChanged: onJoinChanged,
                      ),
                    ],
                  ),
                  if (progress < 0.3 &&
                      community['description'] != null &&
                      community['description'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        community['description'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: dark
                              ? DesignTokens.darkTextSecondary
                              : DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          right: isMod ? 48 : 8,
          child: IconButton(
            icon: const Icon(Icons.search_rounded, size: 20),
            onPressed: () => context.push('/search?c=$slug'),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ),
        if (isMod)
          Positioned(
            top: MediaQuery.of(context).padding.top + 4,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.shield_outlined, size: 20),
              onPressed: () => context.push('/y/$slug/mod'),
              color: Colors.white,
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.3),
              ),
            ),
          ),
      ],
    );
  }
}

class _JoinFavButtons extends StatelessWidget {
  final String slug;
  final bool isMember;
  final bool isFav;
  final VoidCallback onJoinChanged;

  const _JoinFavButtons({
    required this.slug,
    required this.isMember,
    required this.isFav,
    required this.onJoinChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isMember)
          Mutation(
            options: MutationOptions(document: gql(kToggleFavourite)),
            builder: (runFav, _) {
              return IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? DesignTokens.warning : null,
                  size: 20,
                ),
                onPressed: () {
                  runFav({'slug': slug});
                  onJoinChanged();
                },
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                padding: EdgeInsets.zero,
              );
            },
          ),
        Mutation(
          options: MutationOptions(
            document: gql(isMember ? kLeaveCommunity : kJoinCommunity),
          ),
          builder: (runJoin, joinResult) {
            final busy = joinResult?.isLoading ?? false;
            return FilledButton.tonal(
              onPressed: busy
                  ? null
                  : () {
                      if (isMember) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Leave community?'),
                            content: Text('Leave y/$slug?'),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  runJoin({'slug': slug});
                                  onJoinChanged();
                                },
                                child: const Text('Leave',
                                    style:
                                        TextStyle(color: DesignTokens.error)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        runJoin({'slug': slug});
                        onJoinChanged();
                      }
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  : Text(
                      isMember ? 'Joined' : 'Join',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 12),
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _FilterBarDelegate({required this.child});

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 160;
  @override
  bool shouldRebuild(_) => false;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }
}
