import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardAdaptivePlanCard extends StatelessWidget {
  final String planSummary;
  final List<Map> tasks;
  final bool dark;
  const DashboardAdaptivePlanCard(
      {super.key,
      required this.planSummary,
      required this.tasks,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                      color: DesignTokens.info.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.event_note_rounded,
                      color: DesignTokens.info, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('Adaptive Study Plan',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800))),
              ],
            ),
            if (planSummary.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(planSummary,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: DesignTokens.textSecondary, height: 1.5)),
            ],
            if (tasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...tasks.take(3).map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                              color:
                                  DesignTokens.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.chevron_right_rounded,
                              size: 14, color: DesignTokens.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(
                                '${task['title'] ?? 'Task'}${task['reason'] != null ? ' — ${task['reason']}' : ''}',
                                style: const TextStyle(
                                    fontSize: 13, height: 1.4))),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 12),
            FilledButton.tonal(
                onPressed: () => context.push('/ai-tutor'),
                child: const Text('Open AI Tutor')),
          ],
        ),
      ),
    );
  }
}
