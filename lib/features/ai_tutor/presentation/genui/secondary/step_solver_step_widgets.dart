import 'package:flutter/material.dart';
import 'step_solver_data.dart';

class HiddenStep extends StatelessWidget {
  final int stepNumber;
  final ThemeData theme;
  final ColorScheme cs;

  const HiddenStep({
    super.key,
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

class RevealedStep extends StatefulWidget {
  final StepData step;
  final int index;
  final ThemeData theme;
  final ColorScheme cs;
  final VoidCallback onExplain;

  const RevealedStep({
    super.key,
    required this.step,
    required this.index,
    required this.theme,
    required this.cs,
    required this.onExplain,
  });

  @override
  State<RevealedStep> createState() => _RevealedStepState();
}

class _RevealedStepState extends State<RevealedStep>
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
