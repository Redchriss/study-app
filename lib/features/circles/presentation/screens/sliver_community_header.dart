import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import 'community_header.dart';
import 'join_fav_buttons.dart';

class SliverCommunityHeader extends SliverPersistentHeaderDelegate {
  final Map<String, dynamic> community;
  final bool dark;
  final bool isMember;
  final bool isFav;
  final int memberCount;
  final String Function(int) formatCount;
  final String slug;
  final bool isMod;
  final VoidCallback onJoinChanged;

  SliverCommunityHeader({
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
                      JoinFavButtons(
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
