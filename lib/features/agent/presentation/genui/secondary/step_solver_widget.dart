import 'package:flutter/material.dart';
import 'step_solver_data.dart';
import 'step_solver_step_widgets.dart';

class StepSolverWidget extends StatefulWidget {
  final StepSolverData data;
  final VoidCallback onComplete;
  final void Function(int stepNumber) onExplainStep;

  const StepSolverWidget({
    super.key,
    required this.data,
    required this.onComplete,
    required this.onExplainStep,
  });

  @override
  State<StepSolverWidget> createState() => _StepSolverWidgetState();
}

class _StepSolverWidgetState extends State<StepSolverWidget>
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
          ? RevealedStep(
              step: step,
              index: index,
              theme: theme,
              cs: cs,
              onExplain: () => widget.onExplainStep(step.stepNumber),
            )
          : HiddenStep(stepNumber: step.stepNumber, theme: theme, cs: cs),
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
