import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardWeeklyInsights extends ConsumerWidget {
  const DashboardWeeklyInsights({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(
        document: gql(kWeeklyInsights),
        fetchPolicy: FetchPolicy.cacheFirst,
        pollInterval: const Duration(minutes: 10),
      ),
      builder: (result, {refetch, fetchMore}) {
        if (result.isLoading || result.hasException) {
          return const SizedBox.shrink();
        }

        final data = result.data?['weeklyInsights'] as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final quizzesTaken = (data['totalQuizzesTaken'] as num?)?.toInt() ?? 0;
        final questionsAnswered =
            (data['questionsAnswered'] as num?)?.toInt() ?? 0;
        final avgScore = (data['averageScore'] as num?)?.toDouble() ?? 0.0;
        final timeSpent =
            (data['totalTimeSpentMinutes'] as num?)?.toInt() ?? 0;
        final trend = data['scoreTrend'] as String? ?? 'stable';
        final recentTopics = (data['recentTopics'] as List?) ?? [];

        if (quizzesTaken == 0 && questionsAnswered == 0) {
          return const SizedBox.shrink();
        }

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
                        color: const Color(0xFFFFD700).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.insights_rounded,
                          color: Color(0xFFFFD700), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('This Week',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                          Text(
                            _trendText(trend),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: DesignTokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    _TrendBadge(trend: trend),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _InsightStat(
                      value: '$quizzesTaken',
                      label: 'Quizzes',
                      icon: Icons.quiz_rounded,
                      color: DesignTokens.primary,
                    ),
                    _InsightStat(
                      value: '$questionsAnswered',
                      label: 'Questions',
                      icon: Icons.help_outline_rounded,
                      color: DesignTokens.accent,
                    ),
                    _InsightStat(
                      value: '${avgScore.round()}%',
                      label: 'Avg Score',
                      icon: Icons.trending_up_rounded,
                      color: avgScore >= 70
                          ? DesignTokens.success
                          : DesignTokens.warning,
                    ),
                    _InsightStat(
                      value: _formatTime(timeSpent),
                      label: 'Time',
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFF7C4DFF),
                    ),
                  ],
                ),
                if (recentTopics.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  const Text('Recent activity',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  ...recentTopics.take(3).map((t) {
                    final topic = t as Map<String, dynamic>?;
                    final score =
                        (topic?['score'] as num?)?.toDouble() ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: score >= 70
                                  ? DesignTokens.success
                                  : score >= 40
                                      ? DesignTokens.warning
                                      : DesignTokens.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              topic?['quizTitle']?.toString() ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                          Text('${score.round()}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: score >= 70
                                      ? DesignTokens.success
                                      : score >= 40
                                          ? DesignTokens.warning
                                          : DesignTokens.error)),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms);
      },
    );
  }

  String _trendText(String trend) {
    switch (trend) {
      case 'improving':
        return 'Your scores are trending up!';
      case 'declining':
        return 'Scores dipped this week — review weak areas.';
      default:
        return 'Steady performance this week.';
    }
  }

  String _formatTime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
  }
}

class _TrendBadge extends StatelessWidget {
  final String trend;
  const _TrendBadge({required this.trend});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    switch (trend) {
      case 'improving':
        icon = Icons.arrow_upward_rounded;
        color = DesignTokens.success;
        break;
      case 'declining':
        icon = Icons.arrow_downward_rounded;
        color = DesignTokens.error;
        break;
      default:
        icon = Icons.trending_flat_rounded;
        color = DesignTokens.textTertiary;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 16),
    );
  }
}

class _InsightStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _InsightStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: DesignTokens.textTertiary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
