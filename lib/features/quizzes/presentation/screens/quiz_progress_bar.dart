import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class AchievementProgressBar extends StatelessWidget {
  final int answered;
  final int total;
  final int score;

  const AchievementProgressBar({
    super.key,
    required this.answered,
    required this.total,
    required this.score,
  });

  double get _ratio => total > 0 ? answered / total : 0.0;

  String get _milestoneLabel {
    if (answered == 0) return 'Begin';
    final pct = (_ratio * 100).round();
    if (pct >= 100) return 'Mastered';
    if (pct >= 75) return 'Almost there';
    if (pct >= 50) return 'Halfway';
    if (pct >= 25) return 'Good start';
    return 'In progress';
  }

  IconData get _milestoneIcon {
    if (_ratio >= 1.0) return Icons.workspace_premium;
    if (_ratio >= 0.75) return Icons.rocket_launch;
    if (_ratio >= 0.5) return Icons.flag;
    if (_ratio >= 0.25) return Icons.trending_up;
    return Icons.fiber_manual_record;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_milestoneIcon, size: 14, color: DesignTokens.primary),
              const SizedBox(width: 6),
              Text(
                _milestoneLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: dark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Text(
                '$score/$total correct',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: List.generate(total, (i) {
                  final isAnswered = i < answered;

                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: isAnswered
                            ? DesignTokens.primary
                            : (dark
                                ? DesignTokens.darkBorder
                                : DesignTokens.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
