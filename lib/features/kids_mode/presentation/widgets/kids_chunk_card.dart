import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';

class KidsChunkCard extends StatelessWidget {
  const KidsChunkCard({
    super.key,
    required this.index,
    required this.emoji,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  final int index;
  final String emoji;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: DesignTokens.durFast,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? KidsVisualTheme.pathBlue.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? KidsVisualTheme.pathBlue
                : Colors.white.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? KidsVisualTheme.chunkyShadow(
                  KidsVisualTheme.pathBlue.withValues(alpha: 0.3),
                  dy: 2)
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Center(
                  child: Text(emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? KidsVisualTheme.ink
                          : KidsVisualTheme.ink.withValues(alpha: 0.85),
                      height: 1.45,
                    ))),
            if (isSelected)
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: KidsVisualTheme.pathBlue, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}
