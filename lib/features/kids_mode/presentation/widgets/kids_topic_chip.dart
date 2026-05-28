import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsTopicChip extends StatelessWidget {
  const KidsTopicChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? KidsVisualTheme.pathBlue
          : Colors.white.withValues(alpha: 0.88),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : KidsVisualTheme.ink,
            ),
          ),
        ),
      ),
    );
  }
}
