import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kids_quiz_shared.dart';

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
          ...options.asMap().entries.map((e) => _QuizOptionButton(
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

class _QuizOptionButton extends StatelessWidget {
  const _QuizOptionButton({
    required this.index,
    required this.text,
    required this.correctIdx,
    required this.selected,
    required this.answered,
    this.onTap,
  });

  final int index;
  final String text;
  final int correctIdx;
  final int? selected;
  final bool answered;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isCorrect = index == correctIdx;
    final isSelected = selected == index;

    Color bg = Colors.white;
    Color fg = KidsVisualTheme.ink;
    Color border = KidsVisualTheme.ink.withValues(alpha: 0.08);
    IconData? trailingIcon;

    if (answered) {
      if (isCorrect) {
        bg = DesignTokens.success;
        fg = Colors.white;
        border = DesignTokens.success;
        trailingIcon = Icons.check_circle_rounded;
      } else if (isSelected) {
        bg = DesignTokens.error;
        fg = Colors.white;
        border = DesignTokens.error;
        trailingIcon = Icons.cancel_rounded;
      } else {
        bg = Colors.white.withValues(alpha: 0.6);
        fg = KidsVisualTheme.inkMuted;
      }
    }

    return Semantics(
      button: true,
      label:
          'Option ${String.fromCharCode(65 + index)}: $text${answered ? isCorrect ? ', correct' : isSelected ? ', incorrect' : '' : ''}',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: DesignTokens.durFast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border, width: 2),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: fg.withValues(
                        alpha: answered && isCorrect ? 0.25 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text(String.fromCharCode(65 + index),
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: fg,
                              fontSize: 16))),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(text,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: fg))),
                if (trailingIcon != null)
                  Icon(trailingIcon, color: fg, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
