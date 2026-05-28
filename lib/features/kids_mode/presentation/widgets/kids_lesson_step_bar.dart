import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';

/// Two-step lesson flow: story → quiz (Duolingo-like path clarity).
class KidsLessonStepBar extends StatelessWidget {
  const KidsLessonStepBar({
    super.key,
    required this.inQuiz,
  });

  final bool inQuiz;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StepDot(step: 1, label: 'Story', active: !inQuiz, done: inQuiz),
        Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: KidsVisualTheme.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(99),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: inQuiz ? 1.0 : 0.5,
              child: Container(
                decoration: BoxDecoration(
                  gradient: KidsVisualTheme.ctaGradient,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        _StepDot(step: 2, label: 'Quiz', active: inQuiz, done: false),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.step,
    required this.label,
    required this.active,
    required this.done,
  });

  final int step;
  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color ring = active || done
        ? KidsVisualTheme.trailGreen
        : KidsVisualTheme.inkMuted.withValues(alpha: 0.25);
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? KidsVisualTheme.trailGreen : Colors.white,
            border: Border.all(color: ring, width: 3),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: KidsVisualTheme.trailGreen.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    '$step',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: active
                          ? KidsVisualTheme.trailGreen
                          : KidsVisualTheme.inkMuted,
                      height: 1,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color:
                active || done ? KidsVisualTheme.ink : KidsVisualTheme.inkMuted,
          ),
        ),
      ],
    );
  }
}
