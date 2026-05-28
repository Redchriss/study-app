import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardProgressSnapshotCard extends StatelessWidget {
  final dynamic snap;
  final List<String> strongestTopics;
  final List<String> weakestTopics;
  final bool dark;

  const DashboardProgressSnapshotCard({
    super.key,
    required this.snap,
    required this.strongestTopics,
    required this.weakestTopics,
    required this.dark,
  });

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
            Text('Your Progress',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatPill(
                    value: '${snap?['masteryPercent'] ?? 0}%',
                    label: 'Mastery',
                    color: DesignTokens.success),
                _StatPill(
                    value: '${snap?['avgQuizScore'] ?? 0}%',
                    label: 'Avg Score',
                    color: DesignTokens.primary),
                _StatPill(
                    value: '${snap?['questionsPracticed'] ?? 0}',
                    label: 'Questions',
                    color: DesignTokens.secondary),
                _StatPill(
                    value: '${snap?['attemptCount'] ?? 0}',
                    label: 'Attempts',
                    color: DesignTokens.info),
              ],
            ),
            if (strongestTopics.isNotEmpty || weakestTopics.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 10),
              if (strongestTopics.isNotEmpty)
                Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 15, color: DesignTokens.success),
                  const SizedBox(width: 6),
                  const Text('Strong: ',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Expanded(
                      child: Text(strongestTopics.take(2).join(', '),
                          style: const TextStyle(
                              fontSize: 13, color: DesignTokens.textSecondary),
                          overflow: TextOverflow.ellipsis)),
                ]),
              if (weakestTopics.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.trending_up_rounded,
                      size: 15, color: DesignTokens.warning),
                  const SizedBox(width: 6),
                  const Text('Focus on: ',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  Expanded(
                      child: Text(weakestTopics.take(2).join(', '),
                          style: const TextStyle(
                              fontSize: 13, color: DesignTokens.textSecondary),
                          overflow: TextOverflow.ellipsis)),
                ]),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatPill(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: DesignTokens.textTertiary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
