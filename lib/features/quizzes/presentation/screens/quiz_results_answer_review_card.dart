import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class QuizResultsLabeledText extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const QuizResultsLabeledText(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ',
          style: TextStyle(
              fontSize: 11,
              color: DesignTokens.textTertiary,
              fontWeight: FontWeight.w500)),
      Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color))),
    ]);
  }
}

class QuizResultsAnswerReviewCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> answer;
  final bool dark;
  const QuizResultsAnswerReviewCard(
      {required this.index, required this.answer, required this.dark});

  @override
  Widget build(BuildContext context) {
    final isCorrect = answer['isCorrect'] == true;
    final yourAnswer =
        (answer['selectedAnswer'] as Map?)?['answerText'] as String?;
    final correctAnswer =
        (answer['correctAnswer'] as Map?)?['answerText'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? DesignTokens.success.withValues(alpha: 0.3)
              : DesignTokens.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isCorrect
                  ? DesignTokens.success.withValues(alpha: 0.1)
                  : DesignTokens.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 12,
                  color: isCorrect ? DesignTokens.success : DesignTokens.error),
              const SizedBox(width: 4),
              Text(isCorrect ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isCorrect
                          ? DesignTokens.success
                          : DesignTokens.error)),
            ]),
          ),
          const Spacer(),
          Text('Q${index + 1}',
              style: TextStyle(
                  fontSize: 11,
                  color: dark
                      ? DesignTokens.darkTextTertiary
                      : DesignTokens.textTertiary)),
        ]),
        if (!isCorrect && correctAnswer != null) ...[
          const SizedBox(height: 8),
          QuizResultsLabeledText(
              label: 'Correct answer',
              text: correctAnswer,
              color: DesignTokens.success),
        ],
        if (yourAnswer != null) ...[
          const SizedBox(height: 4),
          QuizResultsLabeledText(
              label: 'Your answer',
              text: yourAnswer,
              color:
                  isCorrect ? DesignTokens.textSecondary : DesignTokens.error),
        ],
      ]),
    );
  }
}
