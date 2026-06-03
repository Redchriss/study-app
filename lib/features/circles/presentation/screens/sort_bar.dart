import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'community_filter_constants.dart';

class SortBar extends StatelessWidget {
  final int sortIdx;
  final bool dark;
  final ValueChanged<int> onSortChanged;

  const SortBar({
    super.key,
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
