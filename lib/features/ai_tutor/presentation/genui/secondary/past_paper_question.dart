import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final pastPaperQuestionSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['PastPaperQuestion']),
    'subject': S.string(description: 'Subject name e.g. Biology, Mathematics'),
    'year': S.integer(description: 'MSCE paper year e.g. 2019'),
    'question_number':
        S.string(description: 'Question reference e.g. "Question 3(b)"'),
    'question_text': S.string(
      description: 'Full question text as it appears in the paper',
    ),
    'total_marks': S.integer(description: 'Marks allocated to this question'),
    'marking_guide': S.string(
      description:
          'Internal marking guide — NOT shown to student, used by AI to grade',
    ),
    'submitAction': A2uiSchemas.action(
      description:
          'Fired when student submits answer, context includes studentAnswer string',
    ),
  },
  required: [
    'component',
    'subject',
    'question_text',
    'total_marks',
    'marking_guide',
    'submitAction',
  ],
);

enum _GradingState { unanswered, submitting, graded }

class _PastPaperQuestionData {
  final String subject;
  final int year;
  final String? questionNumber;
  final String questionText;
  final int totalMarks;
  final String markingGuide;
  final String actionName;
  final JsonMap actionContext;

  _PastPaperQuestionData({
    required this.subject,
    required this.year,
    this.questionNumber,
    required this.questionText,
    required this.totalMarks,
    required this.markingGuide,
    required this.actionName,
    required this.actionContext,
  });
  factory _PastPaperQuestionData.fromJson(Map<String, Object?> json) {
    final action = json['submitAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    return _PastPaperQuestionData(
      subject: (json['subject'] as String?) ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      questionNumber: json['question_number'] as String?,
      questionText: (json['question_text'] as String?) ?? '',
      totalMarks: (json['total_marks'] as num?)?.toInt() ?? 0,
      markingGuide: (json['marking_guide'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'submitted',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _PastPaperQuestionWidget extends StatefulWidget {
  final _PastPaperQuestionData data;
  final Future<void> Function(String answer) onSubmit;
  const _PastPaperQuestionWidget({
    required this.data,
    required this.onSubmit,
  });
  @override
  State<_PastPaperQuestionWidget> createState() =>
      _PastPaperQuestionWidgetState();
}

class _PastPaperQuestionWidgetState extends State<_PastPaperQuestionWidget>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  _GradingState _state = _GradingState.unanswered;
  int _charCount = 0;
  late final AnimationController _ctrl;
  late final Animation<double> _entrance;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _entrance = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _controller.addListener(() {
      setState(() => _charCount = _controller.text.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _state = _GradingState.submitting);
    await widget.onSubmit(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme, cs),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                widget.data.questionText,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'serif',
                  height: 1.6,
                ),
              ),
            ),
            if (_state != _GradingState.graded) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                enabled: _state == _GradingState.unanswered,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Type your answer here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  counterText: '$_charCount characters',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      _state == _GradingState.unanswered ? _submit : null,
                  child: _state == _GradingState.submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.description_outlined, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          widget.data.subject,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.data.year.toString(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: cs.tertiaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${widget.data.totalMarks} marks',
            style: theme.textTheme.labelSmall?.copyWith(
              color: cs.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

final pastPaperQuestionItem = CatalogItem(
  name: 'PastPaperQuestion',
  dataSchema: pastPaperQuestionSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _PastPaperQuestionData.fromJson(json);
    return _PastPaperQuestionWidget(
      data: data,
      onSubmit: (answer) async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        final finalContext = Map<String, Object?>.from(resolvedContext);
        finalContext['studentAnswer'] = answer;
        finalContext['markingGuide'] = data.markingGuide;
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: finalContext,
          ),
        );
      },
    );
  },
);
