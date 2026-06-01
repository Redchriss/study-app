import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

const postSorts = ['hot', 'new', 'top', 'rising', 'controversial'];
const sortIcons = {
  'hot': Icons.local_fire_department_rounded,
  'new': Icons.fiber_new_rounded,
  'top': Icons.trending_up_rounded,
  'rising': Icons.show_chart_rounded,
  'controversial': Icons.swap_vert_rounded,
};
const sortLabels = {
  'hot': 'Hot',
  'new': 'New',
  'top': 'Top',
  'rising': 'Rising',
  'controversial': 'Controversial',
};
const timeFilters = ['all', 'hour', 'day', 'week', 'month', 'year'];
const timeFilterLabels = {
  'all': 'All time',
  'hour': 'Past hour',
  'day': 'Today',
  'week': 'This week',
  'month': 'This month',
  'year': 'This year',
};
const timeFilterSorts = {'top', 'controversial'};
const postTypes = <String?>{null, 'TEXT', 'IMAGE', 'VIDEO', 'LINK', 'POLL'};
const postTypeLabels = {
  null: 'All',
  'TEXT': 'Text',
  'IMAGE': 'Images',
  'VIDEO': 'Video',
  'LINK': 'Links',
  'POLL': 'Polls',
};
const postTypeIcons = {
  null: Icons.all_inclusive_rounded,
  'TEXT': Icons.article_outlined,
  'IMAGE': Icons.image_outlined,
  'VIDEO': Icons.videocam_outlined,
  'LINK': Icons.link_rounded,
  'POLL': Icons.poll_outlined,
};

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
          _SortBar(
            sortIdx: sortIdx,
            dark: dark,
            onSortChanged: onSortChanged,
          ),
          if (timeFilterSorts.contains(postSorts[sortIdx]))
            _TimeFilterBar(
              timeFilter: timeFilter,
              dark: dark,
              onTimeFilterChanged: onTimeFilterChanged,
            ),
          _PostTypeBar(
            postType: postType,
            dark: dark,
            onPostTypeChanged: onPostTypeChanged,
          ),
          if (flairs.isNotEmpty)
            _FlairBar(
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

class _SortBar extends StatelessWidget {
  final int sortIdx;
  final bool dark;
  final ValueChanged<int> onSortChanged;

  const _SortBar({
    required this.sortIdx,
    required this.dark,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: postSorts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 2),
        itemBuilder: (_, i) {
          final sort = postSorts[i];
          final selected = i == sortIdx;
          final icon = sortIcons[sort]!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Material(
              color: selected
                  ? DesignTokens.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSortChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: selected
                            ? DesignTokens.primary
                            : DesignTokens.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sortLabels[sort]!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected
                              ? DesignTokens.primary
                              : DesignTokens.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TimeFilterBar extends StatelessWidget {
  final String timeFilter;
  final bool dark;
  final ValueChanged<String> onTimeFilterChanged;

  const _TimeFilterBar({
    required this.timeFilter,
    required this.dark,
    required this.onTimeFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: timeFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final t = timeFilters[i];
          final selected = timeFilter == t;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FilterChip(
              label: Text(
                timeFilterLabels[t]!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? Colors.white
                      : DesignTokens.textSecondary,
                ),
              ),
              selected: selected,
              selectedColor: DesignTokens.primary,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) =>
                  onTimeFilterChanged(t == timeFilter ? 'all' : t),
            ),
          );
        },
      ),
    );
  }
}

class _PostTypeBar extends StatelessWidget {
  final String? postType;
  final bool dark;
  final ValueChanged<String?> onPostTypeChanged;

  const _PostTypeBar({
    required this.postType,
    required this.dark,
    required this.onPostTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: postTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final t = postTypes.elementAt(i);
          final selected = postType == t;
          final icon = postTypeIcons[t]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FilterChip(
              avatar: Icon(
                icon,
                size: 14,
                color: selected ? Colors.white : DesignTokens.textSecondary,
              ),
              label: Text(
                postTypeLabels[t]!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color:
                      selected ? Colors.white : DesignTokens.textSecondary,
                ),
              ),
              selected: selected,
              selectedColor: DesignTokens.primary.withValues(alpha: 0.8),
              checkmarkColor: Colors.white,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) =>
                  onPostTypeChanged(t == postType ? null : t),
            ),
          );
        },
      ),
    );
  }
}

class _FlairBar extends StatelessWidget {
  final List<Map<String, dynamic>> flairs;
  final String? flairId;
  final bool dark;
  final ValueChanged<String?> onFlairChanged;

  const _FlairBar({
    required this.flairs,
    required this.flairId,
    required this.dark,
    required this.onFlairChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: flairs.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 4),
        itemBuilder: (_, i) {
          final selected = i == 0 ? flairId == null : flairId == flairs[i - 1]['id'];
          final label = i == 0 ? 'All' : flairs[i - 1]['text']?.toString() ?? '';
          final color = i == 0
              ? null
              : _parseColor(flairs[i - 1]['backgroundColor']?.toString() ?? '#0079D3');
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: FilterChip(
              label: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? (color != null ? _textColorForBg(color) : Colors.white)
                      : DesignTokens.textSecondary,
                ),
              ),
              selected: selected,
              selectedColor: color ?? DesignTokens.primary,
              checkmarkColor: Colors.white,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) =>
                  onFlairChanged(i == 0 ? null : flairs[i - 1]['id']?.toString()),
            ),
          );
        },
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return DesignTokens.primary;
    }
  }

  Color _textColorForBg(Color bg) {
    return bg.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }
}
