import 'package:flutter/material.dart';

const postSorts = ['hot', 'new', 'top', 'rising', 'controversial'];
const timeFilters = ['all', 'hour', 'day', 'week', 'month', 'year'];
const timeFilterLabels = {
  'all': 'All time',
  'hour': 'Past hour',
  'day': 'Today',
  'week': 'This week',
  'month': 'This month',
  'year': 'This year'
};
const timeFilterSorts = {'top', 'controversial'};
const postTypes = <String?>{null, 'TEXT', 'IMAGE', 'VIDEO', 'LINK', 'POLL'};
const postTypeLabels = {
  null: 'All',
  'TEXT': 'Text',
  'IMAGE': 'Images',
  'VIDEO': 'Video',
  'LINK': 'Links',
  'POLL': 'Polls'
};

/// Horizontal filter bar showing sort, post type, time, and flair chips.
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Sort chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: postSorts.asMap().entries.map((e) {
              final isSelected = e.key == sortIdx;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: Text(e.value.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                  selected: isSelected,
                  onSelected: (_) => onSortChanged(e.key),
                ),
              );
            }).toList(),
          ),
        ),
        // Post type chips
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: postTypes.map((t) {
              final isSelected = postType == t;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(postTypeLabels[t]!,
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                  selected: isSelected,
                  onSelected: (_) =>
                      onPostTypeChanged(t == postType ? null : t),
                ),
              );
            }).toList(),
          ),
        ),
        // Time filter chips (only for top/controversial sorts)
        if (timeFilterSorts.contains(postSorts[sortIdx]))
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: timeFilters.map((t) {
                final isSelected = timeFilter == t;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(timeFilterLabels[t]!,
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    selected: isSelected,
                    onSelected: (_) =>
                        onTimeFilterChanged(t == timeFilter ? 'all' : t),
                  ),
                );
              }).toList(),
            ),
          ),
        // Flair chips
        if (flairs.isNotEmpty)
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: const Text('All Flairs',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    selected: flairId == null,
                    onSelected: (_) => onFlairChanged(null),
                  ),
                ),
                ...flairs.map((f) {
                  final isSelected = flairId == f['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(f['text']?.toString() ?? '',
                          style: const TextStyle(
                              fontSize: 11, fontWeight: FontWeight.w600)),
                      selected: isSelected,
                      onSelected: (_) => onFlairChanged(
                          isSelected ? null : f['id']?.toString()),
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
