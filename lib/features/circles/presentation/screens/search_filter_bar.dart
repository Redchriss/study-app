import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class SearchFilterBar extends StatelessWidget {
  final String sort;
  final String timeFilter;
  final bool dark;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<String> onTimeFilterChanged;

  const SearchFilterBar({
    super.key,
    required this.sort,
    required this.timeFilter,
    required this.dark,
    required this.onSortChanged,
    required this.onTimeFilterChanged,
  });

  static const _sorts = ['relevance', 'hot', 'new', 'top', 'comments'];
  static const _sortLabels = {
    'relevance': 'Relevance',
    'hot': 'Hot',
    'new': 'New',
    'top': 'Top',
    'comments': 'Comments',
  };
  static const _timeFilters = ['all', 'hour', 'day', 'week', 'month', 'year'];
  static const _timeLabels = {
    'all': 'All time',
    'hour': 'Past hour',
    'day': 'Today',
    'week': 'This week',
    'month': 'This month',
    'year': 'This year',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dark ? DesignTokens.darkBorder : DesignTokens.border,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            ..._sorts.map((s) {
              final sel = sort == s;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: ChoiceChip(
                  label: Text(
                    _sortLabels[s]!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  selected: sel,
                  onSelected: (_) => onSortChanged(s),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
            Container(
              width: 1,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: dark ? DesignTokens.darkBorder : DesignTokens.border,
            ),
            ..._timeFilters.map((t) {
              final sel = timeFilter == t;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilterChip(
                  label: Text(
                    _timeLabels[t]!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  selected: sel,
                  onSelected: (_) => onTimeFilterChanged(t),
                  visualDensity: VisualDensity.compact,
                  showCheckmark: false,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
