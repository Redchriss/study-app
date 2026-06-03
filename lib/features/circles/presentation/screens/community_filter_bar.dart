import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'community_filter_constants.dart';
import 'sort_bar.dart';
import 'time_filter_bar.dart';
import 'post_type_bar.dart';
import 'flair_bar.dart';

class CommunityFilterBar extends StatelessWidget {
  final int sortIdx;
  final String timeFilter;
  final String? postType;
  final String? flairId;
  final List<Map<String, dynamic>> flairs;
  final ValueChanged<int> onSortChanged;
  final ValueChanged<String> onTimeFilterChanged;
  final ValueChanged<String?> onPostTypeChanged;
  final ValueChanged<String?> onFlairChanged;

  const CommunityFilterBar({
    super.key,
    required this.sortIdx,
    required this.timeFilter,
    required this.postType,
    required this.flairId,
    required this.flairs,
    required this.onSortChanged,
    required this.onTimeFilterChanged,
    required this.onPostTypeChanged,
    required this.onFlairChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        border: Border(
          bottom: BorderSide(
            color: dark ? DesignTokens.darkBorder : DesignTokens.border,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SortBar(
            sortIdx: sortIdx,
            dark: dark,
            onSortChanged: onSortChanged,
          ),
          if (timeFilterSorts.contains(postSorts[sortIdx]))
            TimeFilterBar(
              timeFilter: timeFilter,
              dark: dark,
              onTimeFilterChanged: onTimeFilterChanged,
            ),
          PostTypeBar(
            postType: postType,
            dark: dark,
            onPostTypeChanged: onPostTypeChanged,
          ),
          if (flairs.isNotEmpty)
            FlairBar(
              flairs: flairs,
              flairId: flairId,
              dark: dark,
              onFlairChanged: onFlairChanged,
            ),
        ],
      ),
    );
  }
}
