import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import 'quiz_feedback_widgets.dart';
import 'quiz_ordering_widget.dart';

class QuizQuestionCard extends StatefulWidget {
  final int index;
  final String questionId;
  final String questionText;
  final String? questionType;
  final List<dynamic> options;
  final String? selectedAnswerId;
  final bool showFeedback;
  final bool? isCorrect;
  final ValueChanged<String> onSelect;

  const QuizQuestionCard({
    super.key,
    required this.index,
    required this.questionId,
    required this.questionText,
    this.questionType,
    required this.options,
    this.selectedAnswerId,
    this.showFeedback = false,
    this.isCorrect,
    required this.onSelect,
  });

  @override
  State<QuizQuestionCard> createState() => _QuizQuestionCardState();
}

class _QuizQuestionCardState extends State<QuizQuestionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late QuestionType _type;

  @override
  void initState() {
    super.initState();
    _type = parseType(widget.questionType);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void didUpdateWidget(QuizQuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.questionId != oldWidget.questionId) {
      _type = parseType(widget.questionType);
      _animCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animCtrl,
          curve: Curves.easeOut,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          DesignTokens.primary,
                          DesignTokens.primaryLight
                        ],
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Q${widget.index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dark
                          ? DesignTokens.darkSurfaceVariant
                          : DesignTokens.surfaceVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _type.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: dark
                            ? DesignTokens.darkTextSecondary
                            : DesignTokens.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.questionText,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(child: _buildOptions(dark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptions(bool dark) {
    switch (_type) {
      case QuestionType.fillBlank:
        return FillBlankInput(
          showFeedback: widget.showFeedback,
          onSubmit: widget.onSelect,
        );
      case QuestionType.ordering:
        return OrderingList(
          key: ValueKey(widget.questionId),
          options: widget.options,
          onOrder: widget.onSelect,
        );
      case QuestionType.matching:
      case QuestionType.mcq:
        return McqOptionsList(
          options: widget.options,
          selectedAnswerId: widget.selectedAnswerId,
          showFeedback: widget.showFeedback,
          isCorrect: widget.isCorrect,
          onSelect: widget.onSelect,
        );
    }
  }
}
