import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../core/graphql/queries/queries.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/widgets/widgets.dart';

class KnowledgeMapScreen extends ConsumerWidget {
  final String subjectCode;

  const KnowledgeMapScreen({super.key, required this.subjectCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
      appBar: AppBar(
        title: Text('$subjectCode — Knowledge Map'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Query(
        options: QueryOptions(
          document: gql(kMyKnowledgeState),
          variables: {'subjectCode': subjectCode},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {refetch, fetchMore}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (result.hasException) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: DesignTokens.error),
                  const SizedBox(height: 8),
                  Text('Could not load knowledge state'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: () => refetch?.call(), child: const Text('Retry')),
                ],
              ),
            );
          }

          final rawList = result.data?['myKnowledgeState'] as List?;
          if (rawList == null || rawList.isEmpty) {
            return const Center(child: Text('No knowledge data yet'));
          }

          final items = rawList.map((e) => KnowledgeItem.fromJson(e)).toList();

          // Group by topic
          final grouped = <String, List<KnowledgeItem>>{};
          for (final item in items) {
            grouped.putIfAbsent(item.topicName, () => []).add(item);
          }

          // Calculate exam readiness
          final mastered = items.where((i) => i.pKnow >= 0.8).length;
          final total = items.length;
          final readiness = total > 0 ? (mastered / total * 100).round() : 0;

          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Exam readiness card
                _buildReadinessCard(context, readiness, mastered, total, dark),
                const SizedBox(height: 20),

                // Knowledge map by topic
                ...grouped.entries.map((entry) {
                  final topicName = entry.key;
                  final concepts = entry.value;
                  final topicMastered = concepts.where((c) => c.pKnow >= 0.8).length;
                  final topicPct = concepts.isNotEmpty ? (topicMastered / concepts.length * 100).round() : 0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(topicName,
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                              ),
                              Text('$topicMastered/${concepts.length}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: DesignTokens.textSecondary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: topicPct / 100,
                              minHeight: 4,
                              backgroundColor: dark ? Colors.white12 : Colors.black12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                topicPct >= 70
                                    ? DesignTokens.success
                                    : topicPct >= 40
                                        ? DesignTokens.warning
                                        : DesignTokens.error,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...concepts.map((c) => _buildConceptRow(c)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReadinessCard(
      BuildContext context, int readiness, int mastered, int total, bool dark) {
    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: readiness / 100,
                  strokeWidth: 6,
                  backgroundColor: dark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    readiness >= 70
                        ? DesignTokens.success
                        : readiness >= 40
                            ? DesignTokens.warning
                            : DesignTokens.error,
                  ),
                ),
                Text('$readiness%',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Exam Readiness',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text('$mastered of $total concepts mastered',
                    style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Text(readiness >= 70
                    ? 'You\'re on track! Keep going.'
                    : readiness >= 40
                        ? 'Focus on weak areas below.'
                        : 'Start with the fundamentals.',
                    style: TextStyle(fontSize: 12, color: DesignTokens.primary)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildConceptRow(KnowledgeItem item) {
    final color = item.pKnow >= 0.8
        ? DesignTokens.success
        : item.pKnow >= 0.4
            ? DesignTokens.warning
            : DesignTokens.error;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(item.conceptName,
                style: const TextStyle(fontSize: 13)),
          ),
          Text('${(item.pKnow * 100).round()}%',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: color,
              )),
        ],
      ),
    );
  }
}

class KnowledgeItem {
  final String conceptSlug;
  final String conceptName;
  final String topicName;
  final String subjectCode;
  final double pKnow;
  final double confidence;
  final int totalObservations;
  final double difficulty;
  final bool isReadyToLearn;
  final List<String> prerequisiteSlugs;

  KnowledgeItem.fromJson(Map<String, dynamic> json)
      : conceptSlug = json['conceptSlug'] as String? ?? '',
        conceptName = json['conceptName'] as String? ?? '',
        topicName = json['topicName'] as String? ?? '',
        subjectCode = json['subjectCode'] as String? ?? '',
        pKnow = (json['pKnow'] as num?)?.toDouble() ?? 0.0,
        confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0,
        totalObservations = (json['totalObservations'] as num?)?.toInt() ?? 0,
        difficulty = (json['difficulty'] as num?)?.toDouble() ?? 0.0,
        isReadyToLearn = json['isReadyToLearn'] as bool? ?? false,
        prerequisiteSlugs = (json['prerequisiteSlugs'] as List?)?.cast<String>() ?? [];
}
