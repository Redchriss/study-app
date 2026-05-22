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
          title: Text('Leaderboard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          centerTitle: false,
          bottom: const TabBar(
            tabs: [Tab(text: 'Top Learners'), Tab(text: 'Top Contributors')],
            indicatorColor: DesignTokens.primary,
            labelColor: DesignTokens.primary,
            labelStyle: TextStyle(fontWeight: FontWeight.w700),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        body: const TabBarView(
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
    final dark = theme.brightness == Brightness.dark;
    
    return Query(
      options: QueryOptions(
        document: gql(kLeaderboardRankings),
        variables: {'category': category, 'limit': 20},
      ),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Center(child: CircularProgressIndicator());
        if (result.hasException)
          return ErrorState(
            message: result.exception?.graphqlErrors.firstOrNull?.message ??
                'Failed to load leaderboard',
            onRetry: () => refetch?.call(),
          );
        final entries = (result.data?['leaderboard'] as List?) ?? [];
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: DesignTokens.warning.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.emoji_events_rounded, size: 64, color: DesignTokens.warning),
                ),
                const SizedBox(height: 24),
                Text('No rankings yet', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  category == 'learners' ? 'Take your first quiz to join the leaderboard!' : 'Answer questions in circles to rank up!',
                  style: TextStyle(color: DesignTokens.textSecondary, fontSize: 15),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          itemCount: entries.length,
          itemBuilder: (_, i) {
            final e = entries[i];
            final int rank = i + 1;
            final isTop3 = rank <= 3;
            
            Color rankColor;
            if (rank == 1) {
              rankColor = const Color(0xFFFFC107); // Gold
            } else if (rank == 2) {
              rankColor = const Color(0xFFE0E0E0); // Silver
            } else if (rank == 3) {
              rankColor = const Color(0xFFCD7F32); // Bronze
            } else {
              rankColor = dark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isTop3 
                    ? rankColor.withValues(alpha: 0.1) 
                    : (dark ? DesignTokens.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTop3 ? rankColor.withValues(alpha: 0.3) : (dark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
                ),
                boxShadow: isTop3 ? DesignTokens.shadowSm(dark) : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44, 
                    height: 44,
                    decoration: BoxDecoration(
                      color: rankColor,
                      shape: BoxShape.circle,
                      boxShadow: isTop3 ? [
                        BoxShadow(
                          color: rankColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ] : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rank', 
                        style: TextStyle(
                          fontSize: isTop3 ? 20 : 16,
                          fontWeight: FontWeight.w900, 
                          color: isTop3 ? Colors.black87 : DesignTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e['username'] ?? 'Anonymous', 
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isTop3 ? DesignTokens.textPrimary : DesignTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 12, color: DesignTokens.success),
                            const SizedBox(width: 4),
                            Text(
                              '${e['questionsCorrect'] ?? 0} correct', 
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary),
                            ),
                            const SizedBox(width: 8),
                            Text('•', style: TextStyle(color: DesignTokens.textTertiary, fontSize: 12)),
                            const SizedBox(width: 8),
                            const Icon(Icons.analytics_rounded, size: 12, color: DesignTokens.primary),
                            const SizedBox(width: 4),
                            Text(
                              '${e['score']?.toStringAsFixed(0) ?? '0'} avg', 
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: DesignTokens.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.quiz_rounded, size: 14, color: DesignTokens.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${e['quizCount'] ?? 0}', 
                          style: const TextStyle(fontSize: 13, color: DesignTokens.primary, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
