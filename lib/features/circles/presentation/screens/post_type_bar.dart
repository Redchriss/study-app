import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'community_filter_constants.dart';

class PostTypeBar extends StatelessWidget {
  final String? postType;
  final bool dark;
  final ValueChanged<String?> onPostTypeChanged;

  const PostTypeBar({
    super.key,
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
                  color: selected ? Colors.white : DesignTokens.textSecondary,
                ),
              ),
              selected: selected,
              selectedColor: DesignTokens.primary.withValues(alpha: 0.8),
              checkmarkColor: Colors.white,
              showCheckmark: false,
              visualDensity: VisualDensity.compact,
              onSelected: (_) => onPostTypeChanged(t == postType ? null : t),
            ),
          );
        },
      ),
    );
  }
}
