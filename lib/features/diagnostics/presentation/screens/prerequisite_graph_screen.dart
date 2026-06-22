import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import 'prerequisite_graph_widgets.dart';

class PrerequisiteGraphScreen extends ConsumerStatefulWidget {
  final String subjectCode;
  const PrerequisiteGraphScreen({super.key, required this.subjectCode});

  @override
  ConsumerState<PrerequisiteGraphScreen> createState() =>
      _PrerequisiteGraphScreenState();
}

class _PrerequisiteGraphScreenState
    extends ConsumerState<PrerequisiteGraphScreen> {
  final _scrollCtrl = ScrollController();
  String? _selectedConcept;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          dark ? DesignTokens.darkBackground : DesignTokens.background,
      appBar: AppBar(
        title: Text('${widget.subjectCode} — Prerequisite Graph'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(DesignTokens.success, 'Mastered'),
                const SizedBox(width: 16),
                _legendDot(DesignTokens.warning, 'Learning'),
                const SizedBox(width: 16),
                _legendDot(DesignTokens.error, 'Not started'),
                const SizedBox(width: 16),
                _legendDot(DesignTokens.textTertiary, 'Unknown'),
              ],
            ),
          ),
          Expanded(
            child: Query(
              options: QueryOptions(
                document: gql(kKnowledgeTree),
                variables: {'subjectId': widget.subjectCode},
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
                        const Icon(Icons.error_outline,
                            size: 48, color: DesignTokens.error),
                        const SizedBox(height: 8),
                        const Text('Could not load knowledge graph'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                            onPressed: () => refetch?.call(),
                            child: const Text('Retry')),
                      ],
                    ),
                  );
                }

                final treeData = result.data?['knowledgeTree'] as List?;
                if (treeData == null || treeData.isEmpty) {
                  return const Center(
                      child: Text('No knowledge graph data yet'));
                }

                return Query(
                  options: QueryOptions(
                    document: gql(kMyKnowledgeState),
                    variables: {'subjectCode': widget.subjectCode},
                    fetchPolicy: FetchPolicy.networkOnly,
                  ),
                  builder: (masteryResult, {refetch, fetchMore}) {
                    final masteryMap = <String, double>{};
                    final masteryList =
                        masteryResult.data?['myKnowledgeState'] as List?;
                    if (masteryList != null) {
                      for (final item in masteryList) {
                        final slug = item['conceptSlug'] as String? ?? '';
                        final pKnow =
                            (item['pKnow'] as num?)?.toDouble() ?? 0.0;
                        if (slug.isNotEmpty) masteryMap[slug] = pKnow;
                      }
                    }

                    final topics = _parseTopics(treeData, masteryMap);

                    return RefreshIndicator(
                      onRefresh: () async => refetch?.call(),
                      child: ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(16),
                        itemCount: topics.length,
                        itemBuilder: (_, i) => TopicGraphCard(
                          topic: topics[i],
                          dark: dark,
                          selectedConcept: _selectedConcept,
                          onSelectConcept: (slug) =>
                              setState(() => _selectedConcept = slug),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<GraphTopic> _parseTopics(
      List treeData, Map<String, double> masteryMap) {
    final topics = <GraphTopic>[];
    for (final topicData in treeData) {
      final topic = topicData['topic'] as Map?;
      final concepts = (topicData['concepts'] as List?) ?? [];
      final prereqs = (topicData['prerequisites'] as List?) ?? [];

      final graphConcepts = <GraphConcept>[];
      for (final c in concepts) {
        final slug = c['slug'] as String? ?? '';
        graphConcepts.add(GraphConcept(
          slug: slug,
          name: c['name'] as String? ?? '',
          conceptType: c['conceptType'] as String? ?? '',
          difficulty: (c['difficulty'] as num?)?.toDouble() ?? 0.0,
          mastery: masteryMap[slug] ?? -1.0,
        ));
      }

      final edges = <GraphEdge>[];
      for (final p in prereqs) {
        final fromSlug =
            (p['fromConcept'] as Map?)?['slug'] as String? ?? '';
        final toSlug =
            (p['toConcept'] as Map?)?['slug'] as String? ?? '';
        final strength = (p['strength'] as num?)?.toDouble() ?? 1.0;
        if (fromSlug.isNotEmpty && toSlug.isNotEmpty) {
          edges.add(GraphEdge(
              fromSlug: fromSlug,
              toSlug: toSlug,
              strength: strength));
        }
      }

      topics.add(GraphTopic(
        name: topic?['name'] as String? ?? '',
        standardOrForm: topic?['standardOrForm'] as String? ?? '',
        concepts: graphConcepts,
        edges: edges,
      ));
    }
    return topics;
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: DesignTokens.textSecondary)),
      ],
    );
  }
}
