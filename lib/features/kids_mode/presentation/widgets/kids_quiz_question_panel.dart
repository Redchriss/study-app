import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kids_quiz_shared.dart';
import 'kids_quiz_option_button.dart';

class KidsQuizQuestionPanel extends StatelessWidget {
  const KidsQuizQuestionPanel({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.selected,
    required this.answered,
    required this.onAnswer,
    required this.onNext,
    required this.onBack,
  });

  final Map<String, dynamic> question;
  final int index;
  final int total;
  final int? selected;
  final bool answered;
  final void Function(int) onAnswer;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final correctIdx = (question['correct'] as num?)?.toInt() ?? 0;
    final options =
        (question['options'] as List?)?.map((o) => o.toString()).toList() ?? [];
    final explanation = question['explanation'] as String? ?? '';
    final progress = (index + 1) / total;

    return Semantics(
      label: 'Question ${index + 1} of $total',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: 'Progress: question ${index + 1} of $total',
            child: Row(
              children: [
                Text('Q${index + 1} of $total',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: KidsVisualTheme.inkMuted,
                        fontSize: 13)),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation(
                          KidsVisualTheme.trailGreen),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            header: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KidsVisualTheme.sunGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: KidsVisualTheme.sunGold.withValues(alpha: 0.4)),
              ),
              child: Text(question['question'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: KidsVisualTheme.ink,
                      height: 1.4)),
            ),
          ),
          const SizedBox(height: 14),
          ...options.asMap().entries.map((e) => KidsQuizOptionButton(
                index: e.key,
                text: e.value,
                correctIdx: correctIdx,
                selected: selected,
                answered: answered,
                onTap: answered ? null : () => onAnswer(e.key),
              )),
          if (answered) ...[
            if (explanation.isNotEmpty)
              Semantics(
                label: 'Explanation: $explanation',
                child: AnimatedContainer(
                  duration: DesignTokens.durNormal,
                  margin: const EdgeInsets.only(top: 4, bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: DesignTokens.success.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Semantics(
                        excludeSemantics: true,
                        child: const Icon(Icons.lightbulb_outline_rounded,
                            color: DesignTokens.success, size: 18),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(explanation,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: KidsVisualTheme.ink,
                                  height: 1.4))),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
            Semantics(
              button: true,
              label: index + 1 < total ? 'Next question' : 'See results',
              child: KidsActionButton(
                icon: index + 1 < total
                    ? Icons.arrow_forward_rounded
                    : Icons.emoji_events_rounded,
                label: index + 1 < total ? 'Next question' : 'See results!',
                color: KidsVisualTheme.trailGreen,
                onTap: onNext,
              ).animate().fadeIn(duration: 250.ms),
            ),
          ],
          const SizedBox(height: 8),
          Semantics(
            button: true,
            label: 'Back to lesson',
            child: TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to lesson'),
              style: TextButton.styleFrom(
                  foregroundColor: KidsVisualTheme.inkMuted),
            ),
          ),
        ],
      ),
    );
  }
}
