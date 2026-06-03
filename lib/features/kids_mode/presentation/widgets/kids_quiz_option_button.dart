import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';

class KidsQuizOptionButton extends StatelessWidget {
  const KidsQuizOptionButton({
    super.key,
    required this.index,
    required this.text,
    required this.correctIdx,
    required this.selected,
    required this.answered,
    this.onTap,
  });

  final int index;
  final String text;
  final int correctIdx;
  final int? selected;
  final bool answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = index == correctIdx;
    final isSelected = selected == index;

    Color bg = Colors.white;
    Color fg = KidsVisualTheme.ink;
    Color border = KidsVisualTheme.ink.withValues(alpha: 0.08);
    IconData? trailingIcon;

    if (answered) {
      if (isCorrect) {
        bg = DesignTokens.success;
        fg = Colors.white;
        border = DesignTokens.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        bg = DesignTokens.error;
        fg = Colors.white;
        border = DesignTokens.error;
        trailingIcon = Icons.cancel_rounded;
      } else {
        bg = Colors.white.withValues(alpha: 0.6);
        fg = KidsVisualTheme.inkMuted;
      }
    }

    return Semantics(
      button: true,
      label:
          'Option ${String.fromCharCode(65 + index)}: $text${answered ? isCorrect ? ', correct' : isSelected ? ', incorrect' : '' : ''}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: DesignTokens.durFast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: fg.withValues(
                        alpha: answered && isCorrect ? 0.25 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(String.fromCharCode(65 + index),
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: fg,
                              fontSize: 16))),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(text,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: fg))),
                if (trailingIcon != null)
                  Icon(trailingIcon, color: fg, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
