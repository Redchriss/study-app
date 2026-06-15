import 'package:flutter/material.dart';
import '../core/theme/design_tokens.dart';

class CentreAiButton extends StatelessWidget {
  final bool isSelected;
  final VoidCallback onTap;

  const CentreAiButton(
      {super.key, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 52,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF7C4DFF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                color: Colors.white.withValues(alpha: isSelected ? 1.0 : 0.9),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'AI',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isSelected
                    ? const Color(0xFF7C4DFF)
                    : DesignTokens.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
