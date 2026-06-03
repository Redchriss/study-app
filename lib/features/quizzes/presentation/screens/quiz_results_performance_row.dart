import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class QuizResultsStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;
  const QuizResultsStatChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class QuizResultsPerformanceRow extends StatelessWidget {
  final int correct;
  final int total;
  final String? timeDisplay;
  final bool dark;
  const QuizResultsPerformanceRow(
      {required this.correct,
      required this.total,
      this.timeDisplay,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    final wrong = total - correct;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        QuizResultsStatChip(
            icon: Icons.check_circle,
            label: '$correct correct',
            color: DesignTokens.success,
            dark: dark),
        const SizedBox(width: 8),
        if (wrong > 0) ...[
          QuizResultsStatChip(
              icon: Icons.cancel,
              label: '$wrong wrong',
              color: DesignTokens.error,
              dark: dark),
          const SizedBox(width: 8),
        ],
        if (timeDisplay != null)
          QuizResultsStatChip(
              icon: Icons.timer_outlined,
              label: timeDisplay!,
              color: DesignTokens.info,
              dark: dark),
      ]),
    );
  }
}
