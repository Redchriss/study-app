import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardQuizHistory extends StatelessWidget {
  final List<Map<String, dynamic>> attempts;
  const DashboardQuizHistory({super.key, required this.attempts});

  @override
  Widget build(BuildContext context) {
    if (attempts.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spSm),
          child: SectionHeader(
            title: 'Recent Quizzes',
            actionLabel: 'See all',
            onAction: () => context.push('/history'),
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
                DesignTokens.spMd, 0, DesignTokens.spMd, 0),
            itemCount: attempts.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: DesignTokens.spSm),
            itemBuilder: (_, i) {
              final a = attempts[i];
              final quizTitle =
                  (a['quiz']?['title'] ?? 'Quiz').toString();
              final score = (a['score'] as num?)?.toDouble() ?? 0.0;
              final correctCount =
                  (a['correctCount'] as num?)?.toInt() ?? 0;
              final totalPoints =
                  (a['totalPoints'] as num?)?.toInt() ?? 0;
              final timeSeconds =
                  (a['timeTakenSeconds'] as num?)?.toInt() ?? 0;
              final attemptId = a['id']?.toString() ?? '';
              final color = score >= 70
                  ? DesignTokens.success
                  : score >= 40
                      ? DesignTokens.warning
                      : DesignTokens.error;

              return AnimatedPress(
                onTap: attemptId.isNotEmpty
                    ? () => context.push('/quiz-results/$attemptId')
                    : null,
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: dark
                        ? DesignTokens.darkSurface
                        : DesignTokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: (dark
                                ? DesignTokens.darkBorder
                                : DesignTokens.border)
                            .withValues(alpha: 0.5)),
                    boxShadow: DesignTokens.shadowSm(dark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text('${score.round()}%',
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            score >= 70
                                ? Icons.check_circle_rounded
                                : Icons.timelapse_rounded,
                            color: color,
                            size: 18,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(quizTitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('$correctCount/$totalPoints correct',
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: DesignTokens.textTertiary)),
                          if (timeSeconds > 0) ...[
                            const SizedBox(width: 6),
                            Text(_formatTime(timeSeconds),
                                style: theme.textTheme.labelSmall
                                    ?.copyWith(
                                        color: DesignTokens.textTertiary)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 550.ms);
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
  }
}
