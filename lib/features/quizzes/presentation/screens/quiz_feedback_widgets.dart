import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';

enum QuestionType { mcq, fillBlank, ordering, matching }

QuestionType parseType(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'fill_blank':
    case 'fillblank':
    case 'text':
      return QuestionType.fillBlank;
    case 'ordering':
    case 'order':
      return QuestionType.ordering;
    case 'matching':
    case 'match':
      return QuestionType.matching;
    default:
      return QuestionType.mcq;
  }
}

extension QuestionTypeLabel on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.mcq:
        return 'Multiple Choice';
      case QuestionType.fillBlank:
        return 'Fill in the Blank';
      case QuestionType.ordering:
        return 'Ordering';
      case QuestionType.matching:
        return 'Matching';
    }
  }
}

class McqOptionsList extends StatelessWidget {
  final List<dynamic> options;
  final String? selectedAnswerId;
  final bool showFeedback;
  final bool? isCorrect;
  final ValueChanged<String> onSelect;

  const McqOptionsList({
    super.key,
    required this.options,
    this.selectedAnswerId,
    this.showFeedback = false,
    this.isCorrect,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: options.map((opt) {
        final optId = opt['id'] as String? ?? '';
        final selected = selectedAnswerId == optId;
        final feedbackColor = showFeedback
            ? (isCorrect == true ? DesignTokens.success : DesignTokens.error)
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: showFeedback
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onSelect(optId);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: feedbackColor != null
                    ? feedbackColor.withValues(alpha: 0.08)
                    : selected
                        ? DesignTokens.primary.withValues(alpha: 0.08)
                        : (dark
                            ? DesignTokens.darkSurfaceVariant
                            : DesignTokens.surface),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: feedbackColor ??
                      (selected
                          ? DesignTokens.primary
                          : (dark
                              ? DesignTokens.darkBorder
                              : DesignTokens.border)),
                  width: feedbackColor != null ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: feedbackColor ??
                          (selected
                              ? DesignTokens.primary
                              : Colors.transparent),
                      border: Border.all(
                        color: feedbackColor ??
                            (selected
                                ? DesignTokens.primary
                                : DesignTokens.textTertiary),
                        width: 2,
                      ),
                    ),
                    child: feedbackColor != null
                        ? Icon(
                            isCorrect == true ? Icons.check : Icons.close,
                            size: 12,
                            color: Colors.white,
                          )
                        : (selected
                            ? const Icon(Icons.check,
                                size: 12, color: Colors.white)
                            : null),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      opt['answerText'] ?? '',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class FillBlankInput extends StatefulWidget {
  final bool showFeedback;
  final ValueChanged<String> onSubmit;

  const FillBlankInput({
    super.key,
    this.showFeedback = false,
    required this.onSubmit,
  });

  @override
  State<FillBlankInput> createState() => _FillBlankInputState();
}

class _FillBlankInputState extends State<FillBlankInput> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _ctrl.text.trim();
    if (text.isNotEmpty) widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Type your answer...',
            filled: true,
            fillColor: dark
                ? DesignTokens.darkSurfaceVariant
                : DesignTokens.surfaceVariant,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(fontSize: 16),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          enabled: !widget.showFeedback,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.showFeedback ? null : _submit,
            icon: const Icon(Icons.check),
            label: const Text('Submit Answer'),
          ),
        ),
      ],
    );
  }
}
