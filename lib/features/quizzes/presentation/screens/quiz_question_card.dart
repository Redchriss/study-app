import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class QuizQuestionCard extends StatelessWidget {
  final int index;
  final String questionId;
  final String questionText;
  final List<dynamic> options;
  final String? selectedAnswerId;
  final ValueChanged<String> onSelect;

  const QuizQuestionCard({
    super.key,
    required this.index,
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.selectedAnswerId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            'Q${index + 1}. $questionText',
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ...options.map((opt) {
            final optId = opt['id'] as String? ?? '';
            final selected = selectedAnswerId == optId;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSelect(optId),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: selected
                            ? DesignTokens.primary
                            : DesignTokens.border),
                    borderRadius: BorderRadius.circular(12),
                    color: selected
                        ? DesignTokens.primary.withValues(alpha: 0.08)
                        : null,
                  ),
                  child: Row(children: [
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: selected
                          ? DesignTokens.primary
                          : DesignTokens.textTertiary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(opt['answerText'] ?? '',
                            style: theme.textTheme.bodyMedium)),
                  ]),
                ),
              ),
            );
          }),
        ]),
      ),
    );
  }
}
