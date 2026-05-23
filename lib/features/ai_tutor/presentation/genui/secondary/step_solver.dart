import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final stepSolverSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['StepSolver']),
    'problem_statement':
        S.string(description: 'The full question or problem to solve'),
    'subject': S.string(
      enumValues: ['Mathematics', 'Physics', 'Chemistry', 'Biology', 'Other'],
    ),
    'steps': S.list(
      description: 'Between 3 and 7 steps',
      items: S.object(properties: {
        'step_number': S.integer(description: 'Step number starting from 1'),
        'action': S.string(description: 'What is done in this step'),
        'working': S.string(
          description: 'The actual working (equations, logic)',
        ),
        'explanation': S.string(
          description: 'Why this step is taken',
        ),
      }),
    ),
    'final_answer': S.string(description: 'The final answer'),
    'solverCompleteAction': A2uiSchemas.action(
      description: 'Dispatched when student reaches the final step',
    ),
  },
  required: [
    'component',
    'problem_statement',
    'steps',
    'final_answer',
    'solverCompleteAction',
  ],
);

class _StepData {
  final int stepNumber;
  final String action;
  final String working;
  final String explanation;

  _StepData({
    required this.stepNumber,
    required this.action,
    required this.working,
    required this.explanation,
  });

  factory _StepData.fromJson(Map<String, Object?> json) {
    return _StepData(
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 0,
      action: (json['action'] as String?) ?? '',
      working: (json['working'] as String?) ?? '',
      explanation: (json['explanation'] as String?) ?? '',
    );
  }
}

class _StepSolverData {
  final String problemStatement;
  final String subject;
  final List<_StepData> steps;
  final String finalAnswer;
  final String actionName;
  final JsonMap actionContext;

  _StepSolverData({
    required this.problemStatement,
    required this.subject,
    required this.steps,
    required this.finalAnswer,
    required this.actionName,
    required this.actionContext,
  });

  factory _StepSolverData.fromJson(Map<String, Object?> json) {
    final action = json['solverCompleteAction'] as JsonMap?;
    final event = action?['event'] as JsonMap?;
    final stepsRaw = json['steps'] as List<dynamic>?;
    return _StepSolverData(
      problemStatement: (json['problem_statement'] as String?) ?? '',
      subject: (json['subject'] as String?) ?? 'Mathematics',
      steps: stepsRaw
              ?.map((e) => _StepData.fromJson(e as Map<String, Object?>))
              .toList() ??
          [],
      finalAnswer: (json['final_answer'] as String?) ?? '',
      actionName: (event?['name'] as String?) ?? 'solver_complete',
      actionContext: (event?['context'] as JsonMap?) ?? {},
    );
  }
}

class _StepSolverWidget extends StatefulWidget {
  final _StepSolverData data;
  final VoidCallback onComplete;
  final void Function(int stepNumber) onExplainStep;

  const _StepSolverWidget({
    required this.data,
    required this.onComplete,
    required this.onExplainStep,
  });

  @override
  State<_StepSolverWidget> createState() => _StepSolverWidgetState();
}

class _StepSolverWidgetState extends State<_StepSolverWidget>
    with SingleTickerProviderStateMixin {
  int _revealedSteps = 0;
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
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _revealNext() {
    setState(() {
      _revealedSteps++;
    });
    if (_revealedSteps >= widget.data.steps.length) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final allRevealed = _revealedSteps >= widget.data.steps.length;

    return FadeTransition(
      opacity: _entrance,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProblemHeader(theme, cs),
            const SizedBox(height: 16),
            ...List.generate(widget.data.steps.length, (i) {
              return _buildStepBox(i, theme, cs);
            }),
            if (allRevealed) ...[
              const SizedBox(height: 12),
              _buildFinalAnswer(theme, cs),
            ],
            if (!allRevealed) ...[
              const SizedBox(height: 16),
              Center(
                child: FilledButton.icon(
                  onPressed: _revealNext,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: Text(
                    _revealedSteps == 0
                        ? 'Show first step'
                        : 'Show next step ($_revealedSteps/${widget.data.steps.length})',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProblemHeader(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.functions, size: 18, color: cs.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                widget.data.subject,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.data.problemStatement,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBox(int index, ThemeData theme, ColorScheme cs) {
    final step = widget.data.steps[index];
    final revealed = index < _revealedSteps;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: revealed
          ? _RevealedStep(
              step: step,
              index: index,
              theme: theme,
              cs: cs,
              onExplain: () => widget.onExplainStep(step.stepNumber),
            )
          : _HiddenStep(stepNumber: step.stepNumber, theme: theme, cs: cs),
    );
  }

  Widget _buildFinalAnswer(ThemeData theme, ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: cs.onSecondaryContainer, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.data.finalAnswer,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HiddenStep extends StatelessWidget {
  final int stepNumber;
  final ThemeData theme;
  final ColorScheme cs;

  const _HiddenStep({
    required this.stepNumber,
    required this.theme,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            'Step $stepNumber — tap to reveal',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealedStep extends StatefulWidget {
  final _StepData step;
  final int index;
  final ThemeData theme;
  final ColorScheme cs;
  final VoidCallback onExplain;

  const _RevealedStep({
    required this.step,
    required this.index,
    required this.theme,
    required this.cs,
    required this.onExplain,
  });

  @override
  State<_RevealedStep> createState() => _RevealedStepState();
}

class _RevealedStepState extends State<_RevealedStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));
    _slideCtrl.forward();
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.cs.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Step ${widget.step.stepNumber}',
                    style: widget.theme.textTheme.labelSmall?.copyWith(
                      color: widget.cs.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: widget.onExplain,
                  icon: const Icon(Icons.help_outline, size: 14),
                  label: const Text('Explain', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.step.action,
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              widget.step.working,
              style: widget.theme.textTheme.bodyLarge?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: widget.cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline,
                      size: 14, color: widget.cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.step.explanation,
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        color: widget.cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final stepSolverItem = CatalogItem(
  name: 'StepSolver',
  dataSchema: stepSolverSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _StepSolverData.fromJson(json);
    return _StepSolverWidget(
      data: data,
      onComplete: () async {
        final resolvedContext = await resolveContext(
          itemContext.dataContext,
          data.actionContext,
        );
        itemContext.dispatchEvent(
          UserActionEvent(
            name: data.actionName,
            sourceComponentId: itemContext.id,
            context: resolvedContext,
          ),
        );
      },
      onExplainStep: (stepNumber) {
        itemContext.dispatchEvent(
          UserActionEvent(
            name: 'explain_step',
            sourceComponentId: itemContext.id,
            context: {'stepNumber': stepNumber},
          ),
        );
      },
    );
  },
);
