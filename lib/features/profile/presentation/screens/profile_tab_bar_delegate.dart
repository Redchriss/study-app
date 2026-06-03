import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ProfileTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const ProfileTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: dark ? DesignTokens.darkBackground : DesignTokens.background,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(ProfileTabBarDelegate old) => false;
}
