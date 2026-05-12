import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Leaderboard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          centerTitle: true,
          bottom: TabBar(
            tabs: const [Tab(text: 'Top Learners'), Tab(text: 'Top Contributors')],
            indicatorColor: DesignTokens.primary,
            labelColor: DesignTokens.primary,
          ),
        ),
        body: TabBarView(
          children: [_LeaderboardTab(category: 'learners'), _LeaderboardTab(category: 'contributors')],
        ),
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final String category;
  const _LeaderboardTab({required this.category});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Query(
      options: QueryOptions(
        document: gql(kLeaderboardRankings),
        variables: {'category': category, 'limit': 20},
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: CircularProgressIndicator());
        final entries = (result.data?['leaderboard'] as List?) ?? [];
        if (entries.isEmpty) return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.emoji_events, size: 64, color: DesignTokens.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(category == 'learners' ? 'No learners yet. Take a quiz!' : 'No contributors yet. Answer questions!',
              style: const TextStyle(color: DesignTokens.textTertiary)),
          ]),
        );
        return ListView.builder(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          itemCount: entries.length,
          itemBuilder: (_, i) {
            final e = entries[i];
            final rank = i + 1;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rank == 1 ? DesignTokens.warning : rank == 2 ? Colors.grey[300] : rank == 3 ? Colors.brown[100] : DesignTokens.surfaceVariant,
                  ),
                  child: Center(child: Text('$rank', style: TextStyle(fontWeight: FontWeight.w700, color: rank <= 3 ? Colors.white : DesignTokens.textSecondary))),
                ),
                title: Text(e['username'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${e['questionsCorrect'] ?? 0} correct · ${e['score']?.toStringAsFixed(0) ?? '0'} avg', style: const TextStyle(fontSize: 12)),
                trailing: Text('${e['quizCount'] ?? 0} quizzes', style: const TextStyle(fontSize: 12, color: DesignTokens.primary, fontWeight: FontWeight.w600)),
              ),
            );
          },
        );
      },
    );
  }
}
