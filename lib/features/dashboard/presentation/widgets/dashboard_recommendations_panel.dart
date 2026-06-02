import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/client.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../providers/dashboard_data.dart';

class DashboardRecommendationsPanel extends StatefulWidget {
  final DashboardData data;
  const DashboardRecommendationsPanel({super.key, required this.data});

  @override
  State<DashboardRecommendationsPanel> createState() =>
      _DashboardRecommendationsPanelState();
}

class _DashboardRecommendationsPanelState
    extends State<DashboardRecommendationsPanel> {
  late Future<QueryResult?> _planFuture;

  @override
  void initState() {
    super.initState();
    _planFuture = _loadAdaptivePlan();
  }

  Future<QueryResult?> _loadAdaptivePlan() async {
    try {
      final client = buildGraphQLClient();
      return client.query(
        QueryOptions(
          document: gql(kAdaptiveStudyPlan),
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
      );
    } catch (e) {
      debugPrint('DashboardRecommendationsPanel._loadAdaptivePlan failed: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final hasTopics = d.focusTopic.isNotEmpty || d.confidenceTopic.isNotEmpty;
    final hasStats = d.hasProgressData;

    if (!hasTopics && !hasStats) return const SizedBox.shrink();

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
                    color: const Color(0xFF7C4DFF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Color(0xFF7C4DFF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your Next Focus',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        d.focusTopic.isNotEmpty
                            ? 'Based on your recent activity'
                            : 'Keep up the great work!',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: DesignTokens.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (d.focusTopic.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: DesignTokens.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag_rounded,
                        size: 18, color: DesignTokens.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Focus on: ${d.focusTopic}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            if (d.confidenceTopic.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: DesignTokens.success.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium_rounded,
                        size: 18, color: DesignTokens.success),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text('Strong in: ${d.confidenceTopic}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            if (hasStats) ...[
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(value: '${d.masteryPercent}%', label: 'Mastery'),
                  _MiniStat(value: '${d.avgQuizScore}%', label: 'Avg Score'),
                  _MiniStat(
                      value: '${d.questionsPracticed}', label: 'Questions'),
                  _MiniStat(value: '${d.attemptCount}', label: 'Attempts'),
                ],
              ),
            ],
            const SizedBox(height: 14),
            FutureBuilder<QueryResult?>(
              future: _planFuture,
              builder: (_, snapshot) {
                final tasks = _parseTasks(snapshot.data);
                if (tasks.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 14),
                    const Text('Today\'s study plan:',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...tasks.take(2).map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: DesignTokens.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.chevron_right_rounded,
                                    size: 14, color: DesignTokens.primary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${task['title'] ?? 'Task'}${task['reason'] != null ? ' \u2014 ${task['reason']}' : ''}',
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.push('/ai-tutor'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: Text(d.focusTopic.isNotEmpty
                        ? 'Study $d.focusTopic'
                        : 'Start Study Session'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => context.push('/quizzes'),
                  child: const Text('Quiz'),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 350.ms);
  }

  List<Map<String, dynamic>> _parseTasks(QueryResult? result) {
    if (result == null || result.hasException) return [];
    final plan = result.data?['adaptiveStudyPlan'];
    if (plan is! Map) return [];
    return ((plan['tasksJson'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900, color: DesignTokens.primary)),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                color: DesignTokens.textTertiary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
