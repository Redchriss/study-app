import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/design_tokens.dart';

enum QuestionType { mcq, fillBlank, ordering, matching }

QuestionType _parseType(String? raw) {
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
  final _fillCtrl = TextEditingController();
  late QuestionType _type;
  List<String> _orderedIds = [];
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _type = _parseType(widget.questionType);
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
      _type = _parseType(widget.questionType);
      _animCtrl.forward(from: 0);
      _orderedIds = [];
      _initialized = false;
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _fillCtrl.dispose();
    super.dispose();
  }

  void _initOrdered() {
    if (!_initialized) {
      _orderedIds = widget.options
          .map((o) => o['id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList()
        ..shuffle();
      _initialized = true;
    }
  }

  void _onReorder(int oldIdx, int newIdx) {
    setState(() {
      if (newIdx >= _orderedIds.length) newIdx = _orderedIds.length - 1;
      final id = _orderedIds.removeAt(oldIdx);
      _orderedIds.insert(newIdx, id);
    });
    widget.onSelect(_orderedIds.join(','));
  }

  void _onFillSubmit() {
    final text = _fillCtrl.text.trim();
    if (text.isNotEmpty) widget.onSelect(text);
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
        return _buildFillBlank(dark);
      case QuestionType.ordering:
        return _buildOrdering(dark);
      case QuestionType.matching:
      case QuestionType.mcq:
        return _buildMcq(dark);
    }
  }

  Widget _buildMcq(bool dark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: widget.options.map((opt) {
        final optId = opt['id'] as String? ?? '';
        final selected = widget.selectedAnswerId == optId;
        final feedbackColor = widget.showFeedback
            ? (widget.isCorrect == true
                ? DesignTokens.success
                : DesignTokens.error)
            : null;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: widget.showFeedback
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    widget.onSelect(optId);
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
                            widget.isCorrect == true
                                ? Icons.check
                                : Icons.close,
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

  Widget _buildFillBlank(bool dark) {
    return Column(
      children: [
        TextField(
          controller: _fillCtrl,
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
          onSubmitted: (_) => _onFillSubmit(),
          enabled: !widget.showFeedback,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.showFeedback ? null : _onFillSubmit,
            icon: const Icon(Icons.check),
            label: const Text('Submit Answer'),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdering(bool dark) {
    _initOrdered();
    return ReorderableListView.builder(
      itemCount: _orderedIds.length,
      onReorder: _onReorder,
      buildDefaultDragHandles: false,
      itemBuilder: (_, i) {
        final id = _orderedIds[i];
        final opt = widget.options.firstWhere(
          (o) => o['id'] == id,
          orElse: () => {'answerText': ''},
        );
        return Container(
          key: ValueKey(id),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color:
                dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: dark ? DesignTokens.darkBorder : DesignTokens.border,
            ),
          ),
          child: ListTile(
            leading: ReorderableDragStartListener(
              index: i,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.drag_handle,
                    size: 16, color: DesignTokens.primary),
              ),
            ),
            title: Text(
              '${i + 1}. ${opt['answerText'] ?? ''}',
              style: const TextStyle(fontSize: 14),
            ),
            trailing: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: DesignTokens.primary,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on QuestionType {
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
