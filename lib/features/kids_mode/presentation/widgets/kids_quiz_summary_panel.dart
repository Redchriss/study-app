import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kids_quiz_shared.dart';

class KidsQuizSummaryPanel extends StatelessWidget {
  const KidsQuizSummaryPanel({
    super.key,
    required this.correct,
    required this.total,
    required this.onRetry,
    required this.onBack,
  });

  final int correct;
  final int total;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (correct / total * 100).round() : 0;
    final emoji = pct >= 80
        ? '\u{1F3C6}'
        : pct >= 60
            ? '\u{2B50}'
            : '\u{1F4AA}';
    final message = pct >= 80
        ? 'Brilliant! You are a star!'
        : pct >= 60
            ? 'Great effort! Keep going!'
            : 'Good try! Review the lesson and try again.';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: KidsVisualTheme.ink)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              KidsSummaryPill(
                  label: '$correct',
                  sub: 'Correct',
                  color: DesignTokens.success),
              const SizedBox(width: 16),
              KidsSummaryPill(
                  label: '${total - correct}',
                  sub: 'Missed',
                  color: DesignTokens.error),
              const SizedBox(width: 16),
              KidsSummaryPill(
                  label: '$pct%',
                  sub: 'Score',
                  color: KidsVisualTheme.pathBlue),
            ],
          ),
        ),
        const SizedBox(height: 24),
        KidsActionButton(
            icon: Icons.replay_rounded,
            label: 'Try again',
            color: const Color(0xFF9B59B6),
            onTap: onRetry),
        const SizedBox(height: 10),
        KidsActionButton(
            icon: Icons.arrow_back_rounded,
            label: 'Back to lesson',
            color: KidsVisualTheme.pathBlue,
            onTap: onBack),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
