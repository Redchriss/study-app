import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';

class LeaderboardTab extends ConsumerWidget {
  final String category;
  const LeaderboardTab({super.key, required this.category});

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
        if (result.isLoading) return const LoadingWidget();
        if (result.hasException) {
          return ErrorState(
            message: graphQLErrorMessage(
                result.exception, 'Failed to load leaderboard'),
            onRetry: () => refetch?.call(),
          );
        }
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
                  child: const Icon(Icons.emoji_events_rounded,
                      size: 64, color: DesignTokens.warning),
                ),
                const SizedBox(height: 24),
                Text('No rankings yet',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  category == 'learners'
                      ? 'Take your first quiz to join the leaderboard!'
                      : 'Answer questions in circles to rank up!',
                  style: const TextStyle(
                      color: DesignTokens.textSecondary, fontSize: 15),
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
              rankColor = const Color(0xFFFFC107);
            } else if (rank == 2) {
              rankColor = const Color(0xFFE0E0E0);
            } else if (rank == 3) {
              rankColor = const Color(0xFFCD7F32);
            } else {
              rankColor = dark
                  ? DesignTokens.darkSurfaceVariant
                  : DesignTokens.surfaceVariant;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: isTop3
                    ? rankColor.withValues(alpha: 0.1)
                    : (dark ? DesignTokens.darkSurface : DesignTokens.surface),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isTop3
                      ? rankColor.withValues(alpha: 0.3)
                      : (dark
                          ? DesignTokens.darkBorder
                          : DesignTokens.border),
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
                      boxShadow: isTop3
                          ? [
                              BoxShadow(
                                color: rankColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: isTop3 ? 20 : 16,
                          fontWeight: FontWeight.w900,
                          color: isTop3
                              ? Colors.black87
                              : DesignTokens.textSecondary,
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
                            color: isTop3
                                ? DesignTokens.textPrimary
                                : DesignTokens.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (category == 'learners')
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 12, color: DesignTokens.success),
                              const SizedBox(width: 4),
                              Text(
                                '${e['questionsCorrect'] ?? 0} correct',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              const Text('\u2022',
                                  style: TextStyle(
                                      color: DesignTokens.textTertiary,
                                      fontSize: 12)),
                              const SizedBox(width: 8),
                              const Icon(Icons.analytics_rounded,
                                  size: 12, color: DesignTokens.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${(e['score'] as num?)?.toStringAsFixed(0) ?? '0'} avg',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.textSecondary),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded,
                                  size: 12, color: DesignTokens.secondary),
                              const SizedBox(width: 4),
                              Text(
                                '${e['postKarma'] ?? 0} post karma',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              const Text('\u2022',
                                  style: TextStyle(
                                      color: DesignTokens.textTertiary,
                                      fontSize: 12)),
                              const SizedBox(width: 8),
                              Text(
                                '${e['helpfulAnswers'] ?? 0} answers',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: DesignTokens.textSecondary),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          category == 'learners'
                              ? Icons.quiz_rounded
                              : Icons.star_rounded,
                          size: 14,
                          color: DesignTokens.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          category == 'learners'
                              ? '${e['quizCount'] ?? 0}'
                              : '${e['totalKarma'] ?? 0}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: DesignTokens.primary,
                              fontWeight: FontWeight.w800),
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
