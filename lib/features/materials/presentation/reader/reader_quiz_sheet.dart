import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'material_reader_models.dart';

Future<void> showReaderQuickQuizSheet(
  BuildContext context, {
  required ReaderQuickQuizData quiz,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReaderQuickQuizSheet(quiz: quiz),
  );
}

Future<void> showReaderAiReplySheet(
  BuildContext context, {
  required String title,
  required String anchorLabel,
  required String reply,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        maxChildSize: 0.94,
        minChildSize: 0.42,
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              controller: controller,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(anchorLabel,
                    style: const TextStyle(color: DesignTokens.textSecondary)),
                const SizedBox(height: 16),
                Text(reply, style: const TextStyle(height: 1.55)),
              ],
            ),
          );
        },
      );
    },
  );
}

class _ReaderQuickQuizSheet extends StatefulWidget {
  const _ReaderQuickQuizSheet({required this.quiz});
  final ReaderQuickQuizData quiz;

  @override
  State<_ReaderQuickQuizSheet> createState() => _ReaderQuickQuizSheetState();
}

class _ReaderQuickQuizSheetState extends State<_ReaderQuickQuizSheet> {
  final Map<int, int> _answers = <int, int>{};
  var _submitted = false;

  @override
  Widget build(BuildContext context) {
    final correct = _answers.entries.where((entry) {
      final question = widget.quiz.questions[entry.key];
      return question.answerIndex == entry.value;
    }).length;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.quiz.title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  _submitted
                      ? 'You got $correct / ${widget.quiz.questions.length} correct.'
                      : 'Answer the section quiz before you continue reading.',
                  style: const TextStyle(color: DesignTokens.textSecondary),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    controller: controller,
                    itemCount: widget.quiz.questions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final question = widget.quiz.questions[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: DesignTokens.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Q${index + 1}. ${question.question}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, height: 1.4)),
                            const SizedBox(height: 10),
                            for (var optionIndex = 0;
                                optionIndex < question.options.length;
                                optionIndex++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: _submitted
                                      ? null
                                      : () => setState(
                                          () => _answers[index] = optionIndex),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _answerColor(
                                          question, index, optionIndex),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                          color: _answerBorderColor(
                                              question, index, optionIndex)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _answers[index] == optionIndex
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: _submitted &&
                                                  question.answerIndex ==
                                                      optionIndex
                                              ? DesignTokens.success
                                              : DesignTokens.textTertiary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                                question.options[optionIndex])),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_submitted &&
                                question.explanation.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(question.explanation,
                                  style: const TextStyle(
                                      color: DesignTokens.textSecondary,
                                      height: 1.45)),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitted
                        ? () => Navigator.of(context).pop()
                        : (_answers.length == widget.quiz.questions.length
                            ? () => setState(() => _submitted = true)
                            : null),
                    child: Text(_submitted ? 'Close Quiz' : 'Check Answers'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _answerColor(
      ReaderQuickQuizQuestion question, int questionIndex, int optionIndex) {
    if (!_submitted) {
      return _answers[questionIndex] == optionIndex
          ? DesignTokens.primary.withValues(alpha: 0.08)
          : Colors.transparent;
    }
    if (question.answerIndex == optionIndex)
      return DesignTokens.success.withValues(alpha: 0.12);
    if (_answers[questionIndex] == optionIndex)
      return DesignTokens.error.withValues(alpha: 0.08);
    return Colors.transparent;
  }

  Color _answerBorderColor(
      ReaderQuickQuizQuestion question, int questionIndex, int optionIndex) {
    if (_submitted) {
      if (question.answerIndex == optionIndex) return DesignTokens.success;
      if (_answers[questionIndex] == optionIndex) return DesignTokens.error;
    }
    return _answers[questionIndex] == optionIndex
        ? DesignTokens.primary
        : DesignTokens.border;
  }
}
