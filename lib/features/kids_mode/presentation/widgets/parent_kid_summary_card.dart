import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';

class ParentKidSummaryCard extends StatelessWidget {
  const ParentKidSummaryCard({
    super.key,
    required this.summary,
  });

  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final badges = ((summary['recentBadges'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary['childName']?.toString() ?? 'Learner',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${summary['educationTrack'] == 'ecd' ? 'Early childhood' : 'Standard'} ${summary['standard'] ?? '?'}',
                        style: const TextStyle(color: DesignTokens.textSecondary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Lv ${summary['currentLevel'] ?? 1}',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: DesignTokens.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatPill(icon: Icons.local_fire_department_rounded, label: '${summary['streak'] ?? 0} day streak'),
                _StatPill(icon: Icons.star_rounded, label: '${summary['totalStars'] ?? 0} stars'),
                _StatPill(icon: Icons.check_circle_outline_rounded, label: '${summary['masteredCount'] ?? 0} mastered'),
                _StatPill(icon: Icons.refresh_rounded, label: '${summary['readyReviewCount'] ?? 0} to review'),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Strongest subject: ${summary['strongestSubject'] ?? 'Keep exploring'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              summary['supportTip']?.toString() ?? '',
              style: const TextStyle(color: DesignTokens.textSecondary, height: 1.35),
            ),
            if (badges.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: badges.map((badge) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: DesignTokens.warning.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge['title']?.toString() ?? 'Badge',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: DesignTokens.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: DesignTokens.primary),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
