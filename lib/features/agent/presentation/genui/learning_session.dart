import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';
import '../../../../core/theme/design_tokens.dart';

final learningSessionSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['LearningSession']),
    'title': S.string(description: 'Session title'),
    'current_step': S.integer(description: 'Current step index (0-based)'),
    'total_steps': S.integer(description: 'Total number of steps'),
    'steps': S.list(
      description: 'Step labels',
      items: S.object(
        properties: {
          'label': S.string(description: 'Step label e.g. Q1'),
          'completed': S.boolean(description: 'Whether step is done'),
        },
        required: ['label'],
      ),
    ),
    'children': S.list(
      description: 'Nested component specs for each step',
      items: S.object(),
    ),
  },
  required: ['component', 'title', 'children'],
);

class LearningSessionWidget extends StatefulWidget {
  final String title;
  final List<Map<String, Object?>> steps;
  final List<Map<String, Object?>> children;

  const LearningSessionWidget({
    super.key,
    required this.title,
    required this.steps,
    required this.children,
  });

  @override
  State<LearningSessionWidget> createState() => _LearningSessionWidgetState();
}

class _LearningSessionWidgetState extends State<LearningSessionWidget> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final totalSteps = widget.steps.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        border: Border.all(
            color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                .withValues(alpha: 0.5)),
        boxShadow: DesignTokens.shadowSm(dark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                    '${_currentStep + 1}/$totalSteps',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: DesignTokens.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Step indicators
          Row(
            children: List.generate(totalSteps, (i) {
              final isCompleted = i < _currentStep;
              final isCurrent = i == _currentStep;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isCompleted
                          ? DesignTokens.primary
                          : isCurrent
                              ? DesignTokens.primary.withValues(alpha: 0.5)
                              : (dark
                                  ? DesignTokens.darkBorder
                                  : DesignTokens.border),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          // Step labels
          Row(
            children: List.generate(totalSteps, (i) {
              final label = widget.steps[i]['label']?.toString() ?? 'Step ${i + 1}';
              return Expanded(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            i == _currentStep ? FontWeight.w700 : FontWeight.w500,
                        color: i == _currentStep
                            ? DesignTokens.primary
                            : DesignTokens.textTertiary)),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Current child content
          if (_currentStep < widget.children.length)
            Surface(
              surfaceContext: widget.surfaceController.contextFor(
                'session_step_$_currentStep',
              ),
            ),
          const SizedBox(height: 12),
          // Navigation buttons
          Row(
            children: [
              if (_currentStep > 0)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _currentStep--),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Previous',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              const Spacer(),
              if (_currentStep < totalSteps - 1)
                FilledButton.icon(
                  onPressed: () => setState(() => _currentStep++),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Next',
                      style: TextStyle(fontSize: 12)),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

final learningSessionItem = CatalogItem(
  name: 'LearningSession',
  dataSchema: learningSessionSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final title = json['title'] as String? ?? 'Learning Session';
    final steps = ((json['steps'] as List?) ?? [])
        .cast<Map<String, Object?>>()
        .toList();
    final children = ((json['children'] as List?) ?? [])
        .cast<Map<String, Object?>>()
        .toList();

    return LearningSessionWidget(
      title: title,
      steps: steps,
      children: children,
    );
  },
);
