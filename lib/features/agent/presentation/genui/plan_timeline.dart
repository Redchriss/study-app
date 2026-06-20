import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

final planTimelineSchema = S.object(
  properties: {
    'component': S.string(enumValues: ['PlanTimeline']),
    'title':
        S.string(description: 'The overall goal or title of the study plan'),
    'steps': S.list(
      description: 'The chronological steps in the plan',
      items: S.object(
        properties: {
          'timeframe': S.string(
              description:
                  'When this step occurs (e.g., "Day 1", "Morning", "Next 30 mins")'),
          'task': S.string(description: 'What to do during this step'),
          'duration':
              S.string(description: 'Estimated duration (e.g., "15 mins")'),
        },
        required: ['timeframe', 'task'],
      ),
    ),
  },
  required: ['component', 'title', 'steps'],
);

class _PlanStep {
  final String timeframe;
  final String task;
  final String? duration;

  _PlanStep({required this.timeframe, required this.task, this.duration});

  factory _PlanStep.fromJson(Map<String, Object?> json) {
    return _PlanStep(
      timeframe: json['timeframe'] as String,
      task: json['task'] as String,
      duration: json['duration'] as String?,
    );
  }
}

class _PlanTimelineData {
  final String title;
  final List<_PlanStep> steps;

  _PlanTimelineData({required this.title, required this.steps});

  factory _PlanTimelineData.fromJson(Map<String, Object?> json) {
    try {
      return _PlanTimelineData(
        title: json['title'] as String,
        steps: (json['steps'] as List<Object?>)
            .map((e) => _PlanStep.fromJson(e as Map<String, Object?>))
            .toList(),
      );
    } catch (e) {
      throw Exception('Invalid JSON for _PlanTimelineData: $e');
    }
  }
}

class _PlanTimelineWidget extends StatelessWidget {
  final _PlanTimelineData data;

  const _PlanTimelineWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(data.steps.length, (index) {
            final step = data.steps[index];
            final isLast = index == data.steps.length - 1;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: colorScheme.primary, width: 2),
                          color: colorScheme.surface,
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            color: colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                step.timeframe,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (step.duration != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    step.duration!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            step.task,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

final planTimelineItem = CatalogItem(
  name: 'PlanTimeline',
  dataSchema: planTimelineSchema,
  widgetBuilder: (itemContext) {
    final json = itemContext.data as Map<String, Object?>;
    final data = _PlanTimelineData.fromJson(json);

    return _PlanTimelineWidget(data: data);
  },
);
