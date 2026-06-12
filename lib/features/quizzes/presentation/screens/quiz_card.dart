import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

const _subjectColors = {
  'mathematics': Color(0xFF1B6CA8),
  'maths': Color(0xFF1B6CA8),
  'biology': Color(0xFF27AE60),
  'physics': Color(0xFF7A4D9E),
  'chemistry': Color(0xFFE67E22),
  'history': Color(0xFF8B5E3C),
  'geography': Color(0xFF1F8A70),
  'english': Color(0xFFC0392B),
  'agriculture': Color(0xFF2ECC71),
  'computer': Color(0xFF2C3E50),
  'commerce': Color(0xFFF39C12),
  'life skills': Color(0xFFE91E63),
};

Color _colorFor(String? subject) {
  if (subject == null) return DesignTokens.primary;
  final key = subject.toLowerCase();
  for (final entry in _subjectColors.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return DesignTokens.primary;
}

class QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final bool dark;
  final int index;

  const QuizCard(
      {super.key, required this.quiz, required this.dark, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = quiz['subject'];
    final subjectName = subject is Map ? subject['name']?.toString() ?? '' : '';
    final color = _colorFor(subjectName);
    final difficulty =
        (quiz['difficulty']?.toString().trim().isNotEmpty == true)
            ? quiz['difficulty'].toString()
            : 'medium';
    final questionCount = quiz['questionCount'] ?? 0;
    final durationMin = quiz['durationMinutes'];
    final slug = quiz['slug']?.toString() ?? '';

    final diffColor = difficulty == 'easy'
        ? DesignTokens.success
        : difficulty == 'hard'
            ? DesignTokens.error
            : DesignTokens.warning;

    final diffLabel = difficulty[0].toUpperCase() + difficulty.substring(1);

    return AnimatedPress(
      onTap: slug.isEmpty ? null : () => context.push('/quiz/$slug'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(
            color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                .withValues(alpha: 0.6),
          ),
          boxShadow: DesignTokens.shadowSm(dark),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusXl),
                    bottomLeft: Radius.circular(DesignTokens.radiusXl),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Icon(Icons.quiz_outlined, color: color, size: 22),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        quiz['title']?.toString() ?? 'Untitled quiz',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (subjectName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                subjectName,
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: color),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              diffLabel,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: diffColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.help_outline_rounded,
                              size: 12, color: DesignTokens.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '$questionCount question${questionCount == 1 ? '' : 's'}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: DesignTokens.textTertiary),
                          ),
                          if (durationMin != null) ...[
                            const SizedBox(width: 10),
                            const Icon(Icons.timer_outlined,
                                size: 12, color: DesignTokens.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '$durationMin min',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: DesignTokens.textTertiary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 10),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: DesignTokens.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 45).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, end: 0);
  }
}
