import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

class AgentSnapshotCards extends StatelessWidget {
  const AgentSnapshotCards({
    super.key,
    required this.reviewCount,
    required this.topicStates,
    required this.memories,
    required this.planSummary,
    required this.onGeneratePlan,
  });

  final int reviewCount;
  final List<Map<String, dynamic>> topicStates;
  final List<Map<String, dynamic>> memories;
  final String? planSummary;
  final VoidCallback onGeneratePlan;

  @override
  Widget build(BuildContext context) {
    final topStates = topicStates.take(3).toList();
    final topMemories = memories.take(2).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _MiniCard(
                title: 'Review Now',
                value: '$reviewCount',
                subtitle: reviewCount == 1 ? 'topic due' : 'topics due',
                color: reviewCount > 0
                    ? DesignTokens.warning
                    : DesignTokens.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MiniCard(
                title: 'Tracked Topics',
                value: '${topicStates.length}',
                subtitle: 'learner model',
                color: DesignTokens.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DesignTokens.surfaceVariant,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adaptive plan',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                (planSummary == null || planSummary!.trim().isEmpty)
                    ? 'No active plan yet. Build one from the learner model.'
                    : planSummary!,
                style: const TextStyle(
                    color: DesignTokens.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: onGeneratePlan,
                    icon: const Icon(Icons.route_rounded, size: 18),
                    label: const Text('Build plan'),
                  ),
                  ...topStates.map((state) {
                    final topic = state['topicName']?.toString() ?? 'Topic';
                    final status = state['statusLabel']?.toString() ?? '';
                    return Chip(label: Text('$topic • $status'));
                  }),
                ],
              ),
            ],
          ),
        ),
        if (topMemories.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DesignTokens.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Learner memory',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                ...topMemories.map((memory) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${memory['title'] ?? 'Memory'}: ${memory['body'] ?? ''}',
                      style: const TextStyle(
                          color: DesignTokens.textSecondary, height: 1.35),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DesignTokens.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, color: color)),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: DesignTokens.textSecondary)),
        ],
      ),
    );
  }
}
