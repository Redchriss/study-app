import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'community_filter_constants.dart';

class TimeFilterBar extends StatelessWidget {
  final String timeFilter;
  final bool dark;
  final ValueChanged<String> onTimeFilterChanged;

  const TimeFilterBar({
    super.key,
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
                  color: selected ? Colors.white : DesignTokens.textSecondary,
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
