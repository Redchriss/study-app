import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardSuggestionsPanel extends ConsumerWidget {
  const DashboardSuggestionsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
        document: gql(kSuggestedReviews),
        fetchPolicy: FetchPolicy.cacheFirst,
        pollInterval: const Duration(minutes: 5),
      ),
      builder: (result, {refetch, fetchMore}) {
        if (result.isLoading) return const SizedBox.shrink();
        if (result.hasException) return const SizedBox.shrink();

        final raw = result.data?['suggestedReviews'] as List?;
        if (raw == null || raw.isEmpty) return const SizedBox.shrink();

        final suggestions = raw
            .map((e) => SuggestionItem.fromJson(e as Map<String, dynamic>))
            .toList();

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
                        color: DesignTokens.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_stories_rounded,
                          color: DesignTokens.accent, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ready to Review?',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            suggestions.length == 1
                                ? '1 topic needs your attention'
                                : '${suggestions.length} topics need your attention',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: DesignTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ...suggestions
                    .map((s) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SuggestionCard(
                            item: s,
                            dark: dark,
                            onTap: () => _openTutor(context, s),
                          ),
                        ))
                    .toList(),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openTutor(BuildContext context, SuggestionItem item) {
    // Navigate to AI Tutor with a proactive prompt about this topic
    final prompt = item.reason == 'struggling'
        ? 'Help me with ${item.topicName} in ${item.subjectName ?? "my studies"}'
        : 'Review ${item.topicName} in ${item.subjectName ?? "my studies"}';
    context.push('/ai-tutor', extra: {'prompt': prompt});
  }
}

class SuggestionItem {
  final String topicName;
  final String topicSlug;
  final String? subjectName;
  final int masteryScore;
  final int confidenceScore;
  final int daysSinceStudied;
  final String reason;
  final String reasonLabel;
  final String? statusLabel;

  SuggestionItem.fromJson(Map<String, dynamic> json)
      : topicName = json['topicName'] as String? ?? '',
        topicSlug = json['topicSlug'] as String? ?? '',
        subjectName = json['subjectName'] as String?,
        masteryScore = (json['masteryScore'] as num?)?.toInt() ?? 0,
        confidenceScore = (json['confidenceScore'] as num?)?.toInt() ?? 0,
        daysSinceStudied = (json['daysSinceStudied'] as num?)?.toInt() ?? 0,
        reason = json['reason'] as String? ?? '',
        reasonLabel = json['reasonLabel'] as String? ?? '',
        statusLabel = json['statusLabel'] as String?;

  Color get color {
    switch (reason) {
      case 'due_for_review':
        return DesignTokens.warning;
      case 'struggling':
        return DesignTokens.error;
      case 'top_pick':
        return DesignTokens.success;
      default:
        return DesignTokens.primary;
    }
  }

  IconData get icon {
    switch (reason) {
      case 'due_for_review':
        return Icons.schedule_rounded;
      case 'struggling':
        return Icons.report_problem_rounded;
      case 'top_pick':
        return Icons.trending_up_rounded;
      default:
        return Icons.auto_stories_rounded;
    }
  }
}

class _SuggestionCard extends StatelessWidget {
  final SuggestionItem item;
  final bool dark;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.item,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = item.color;
    final pct = (item.masteryScore / 100).clamp(0.0, 1.0);

    return AnimatedPress(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.topicName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(item.reasonLabel,
                          style: TextStyle(
                              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                      if (item.subjectName != null && item.subjectName!.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text('· ${item.subjectName}',
                            style: TextStyle(
                                fontSize: 11,
                                color: DesignTokens.textSecondary)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textSecondary, size: 20),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.1);
  }
}
