import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';

class AiTutorEmptyState extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  const AiTutorEmptyState({
    super.key,
    required this.suggestions,
    required this.onSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF7C4DFF).withValues(alpha: 0.15),
                    const Color(0xFF1B6CA8).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 42,
                color: Color(0xFF7C4DFF),
              ),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 24),
            Text(
              'What do you want to learn?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: dark
                    ? DesignTokens.darkTextPrimary
                    : DesignTokens.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            Text(
              'Pick a study mode above, then tap a suggestion\nor type your own question.',
              style: TextStyle(
                color: dark
                    ? DesignTokens.darkTextSecondary
                    : DesignTokens.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: suggestions
                  .map((s) => ActionChip(
                        label: Text(s, style: const TextStyle(fontSize: 12)),
                        onPressed: () => onSuggestion(s),
                        avatar: const Icon(Icons.lightbulb_outline_rounded,
                            size: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      )
                          .animate(delay: 300.ms)
                          .fadeIn()
                          .scale(begin: const Offset(0.9, 0.9)))
                  .toList(),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (dark
                        ? DesignTokens.darkSurfaceVariant
                        : DesignTokens.surfaceVariant)
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                      .withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_rounded,
                      size: 18,
                      color: dark
                          ? DesignTokens.darkTextSecondary
                          : DesignTokens.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    '5 study modes · Streaming answers · Adaptive plans',
                    style: TextStyle(
                      fontSize: 11,
                      color: dark
                          ? DesignTokens.darkTextTertiary
                          : DesignTokens.textTertiary,
                    ),
                  ),
                ],
              ),
            ).animate(delay: 400.ms).fadeIn().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
