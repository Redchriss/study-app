import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import 'material_reader_models.dart';

class ReaderAnnotationDraft {
  const ReaderAnnotationDraft({
    required this.noteText,
    required this.color,
  });

  final String noteText;
  final String color;
}

Future<ReaderAnnotationDraft?> showReaderAnnotationComposer(
  BuildContext context, {
  required ReaderStudySelection selection,
}) {
  final noteCtrl = TextEditingController();
  String color = 'amber';

  return showModalBottomSheet<ReaderAnnotationDraft>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Save Highlight', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(
                  selection.selectedText.trim().isEmpty ? selection.anchorLabel : selection.selectedText.trim(),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: DesignTokens.textSecondary, height: 1.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final entry in const [
                      ('amber', Color(0xFFEEC66D)),
                      ('mint', Color(0xFF62C7A5)),
                      ('sky', Color(0xFF6FA8FF)),
                    ])
                      ChoiceChip(
                        label: Text(entry.$1),
                        selected: color == entry.$1,
                        onSelected: (_) => setModalState(() => color = entry.$1),
                        selectedColor: entry.$2.withValues(alpha: 0.22),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Your note',
                    hintText: 'Optional: add a memory hook, definition, or reminder.',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(
                      ReaderAnnotationDraft(noteText: noteCtrl.text.trim(), color: color),
                    ),
                    child: const Text('Save Annotation'),
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  ).whenComplete(noteCtrl.dispose);
}

Future<void> showReaderAnnotationsSheet(
  BuildContext context, {
  required List<ReaderAnnotationData> annotations,
  required Future<void> Function(ReaderAnnotationData annotation) onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (context, controller) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Saved Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                if (annotations.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No annotations yet. Save highlights while reading to build your revision trail.'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: annotations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final annotation = annotations[index];
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: DesignTokens.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: annotationColor(annotation.color),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      annotation.displayAnchor,
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                    if (annotation.selectedText.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        annotation.selectedText,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(color: DesignTokens.textSecondary, height: 1.4),
                                      ),
                                    ],
                                    if (annotation.noteText.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(annotation.noteText),
                                    ],
                                    if (annotation.isHighlight) ...[
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Highlight only',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: DesignTokens.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => onDelete(annotation),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

Future<void> showReaderFlashcardsSheet(
  BuildContext context, {
  required List<ReaderFlashcardData> flashcards,
  required VoidCallback onGenerate,
  required bool isGenerating,
  String? helperText,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ReaderFlashcardsSheet(
      flashcards: flashcards,
      onGenerate: onGenerate,
      isGenerating: isGenerating,
      helperText: helperText,
    ),
  );
}

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
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(anchorLabel, style: const TextStyle(color: DesignTokens.textSecondary)),
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

Color annotationColor(String? color) {
  switch (color) {
    case 'mint':
      return const Color(0xFF62C7A5);
    case 'sky':
      return const Color(0xFF6FA8FF);
    default:
      return const Color(0xFFEEC66D);
  }
}

class _ReaderFlashcardsSheet extends StatefulWidget {
  const _ReaderFlashcardsSheet({
    required this.flashcards,
    required this.onGenerate,
    required this.isGenerating,
    this.helperText,
  });

  final List<ReaderFlashcardData> flashcards;
  final VoidCallback onGenerate;
  final bool isGenerating;
  final String? helperText;

  @override
  State<_ReaderFlashcardsSheet> createState() => _ReaderFlashcardsSheetState();
}

class _ReaderFlashcardsSheetState extends State<_ReaderFlashcardsSheet> {
  var _index = 0;
  var _revealed = false;

  @override
  Widget build(BuildContext context) {
    final hasCards = widget.flashcards.isNotEmpty;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reader Flashcards', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (!hasCards) ...[
              Text(
                widget.helperText ?? 'Generate a flashcard deck from this material and revise it inside study mode.',
                style: const TextStyle(color: DesignTokens.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.isGenerating ? null : widget.onGenerate,
                  icon: widget.isGenerating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(widget.isGenerating ? 'Generating...' : 'Generate Flashcards'),
                ),
              ),
            ] else ...[
              Text(
                '${_index + 1} of ${widget.flashcards.length}',
                style: const TextStyle(color: DesignTokens.textSecondary),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => setState(() => _revealed = !_revealed),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Container(
                    key: ValueKey('${_index}_$_revealed'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _revealed
                            ? const [Color(0xFF0F4C5C), Color(0xFF16596D)]
                            : const [Color(0xFFF6E4B2), Color(0xFFEDC86E)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _revealed ? 'Back' : 'Front',
                          style: TextStyle(
                            color: _revealed ? Colors.white70 : Colors.black54,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _revealed ? widget.flashcards[_index].back : widget.flashcards[_index].front,
                          style: TextStyle(
                            color: _revealed ? Colors.white : Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _revealed ? 'Tap again to return to the prompt.' : 'Tap to reveal the answer.',
                          style: TextStyle(
                            color: _revealed ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _index == 0
                          ? null
                          : () => setState(() {
                                _index -= 1;
                                _revealed = false;
                              }),
                      child: const Text('Previous'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _index == widget.flashcards.length - 1
                          ? null
                          : () => setState(() {
                                _index += 1;
                                _revealed = false;
                              }),
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
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
                Text(widget.quiz.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
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
                            Text(
                              'Q${index + 1}. ${question.question}',
                              style: const TextStyle(fontWeight: FontWeight.w700, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            for (var optionIndex = 0; optionIndex < question.options.length; optionIndex++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: _submitted ? null : () => setState(() => _answers[index] = optionIndex),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: _answerColor(question, index, optionIndex),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _answerBorderColor(question, index, optionIndex),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _answers[index] == optionIndex
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_off,
                                          color: _submitted && question.answerIndex == optionIndex
                                              ? DesignTokens.success
                                              : DesignTokens.textTertiary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(child: Text(question.options[optionIndex])),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (_submitted && question.explanation.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                question.explanation,
                                style: const TextStyle(color: DesignTokens.textSecondary, height: 1.45),
                              ),
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

  Color _answerColor(ReaderQuickQuizQuestion question, int questionIndex, int optionIndex) {
    if (!_submitted) {
      return _answers[questionIndex] == optionIndex ? DesignTokens.primary.withValues(alpha: 0.08) : Colors.transparent;
    }
    if (question.answerIndex == optionIndex) {
      return DesignTokens.success.withValues(alpha: 0.12);
    }
    if (_answers[questionIndex] == optionIndex) {
      return DesignTokens.error.withValues(alpha: 0.08);
    }
    return Colors.transparent;
  }

  Color _answerBorderColor(ReaderQuickQuizQuestion question, int questionIndex, int optionIndex) {
    if (_submitted) {
      if (question.answerIndex == optionIndex) return DesignTokens.success;
      if (_answers[questionIndex] == optionIndex) return DesignTokens.error;
    }
    return _answers[questionIndex] == optionIndex ? DesignTokens.primary : DesignTokens.border;
  }
}
