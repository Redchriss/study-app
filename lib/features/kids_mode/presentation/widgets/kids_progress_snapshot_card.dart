import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsProgressSnapshotCard extends StatelessWidget {
  const KidsProgressSnapshotCard({
    super.key,
    required this.lessonsCompleted,
    required this.quizzesTaken,
    required this.quizzesCorrect,
    required this.starsEarned,
  });

  final int lessonsCompleted;
  final int quizzesTaken;
  final int quizzesCorrect;
  final int starsEarned;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress so far',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: KidsVisualTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _Metric(label: 'Lessons', value: '$lessonsCompleted', color: KidsVisualTheme.pathBlue)),
              const SizedBox(width: 8),
              Expanded(child: _Metric(label: 'Quizzes', value: '$quizzesTaken', color: const Color(0xFF9B59B6))),
              const SizedBox(width: 8),
              Expanded(child: _Metric(label: 'Stars', value: '$starsEarned', color: const Color(0xFFF39C12))),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            quizzesTaken == 0
                ? 'Start with one short quiz after each lesson.'
                : 'Correct answers: $quizzesCorrect of $quizzesTaken',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: KidsVisualTheme.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: KidsVisualTheme.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
