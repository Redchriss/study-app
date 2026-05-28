import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'quiz_card.dart';

class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: Query(
        options: QueryOptions(
            document: gql(kQuizzes), variables: const {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          final quizzes = (result.data?['quizzes'] as List?) ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 100,
                backgroundColor:
                    dark ? DesignTokens.darkSurface : DesignTokens.surface,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quizzes',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (quizzes.isNotEmpty)
                        Text(
                          '${quizzes.length} available',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: DesignTokens.textSecondary),
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => refetch?.call(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),

              // Loading shimmer
              if (result.isLoading && quizzes.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerBox(
                            height: 96, radius: DesignTokens.radiusXl),
                      ),
                      childCount: 8,
                    ),
                  ),
                )

              // Error
              else if (result.hasException && quizzes.isEmpty)
                SliverFillRemaining(
                  child: ErrorState(
                    message: 'Could not load quizzes. Check your connection.',
                    onRetry: () => refetch?.call(),
                  ),
                )

              // Empty
              else if (quizzes.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.quiz_outlined,
                              size: 40, color: DesignTokens.primary),
                        ),
                        const SizedBox(height: 16),
                        Text('No quizzes yet',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'Check back soon — quizzes are added regularly.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: DesignTokens.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )

              // Quiz list
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final q = quizzes[i] as Map<String, dynamic>;
                        return QuizCard(quiz: q, dark: dark, index: i);
                      },
                      childCount: quizzes.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
