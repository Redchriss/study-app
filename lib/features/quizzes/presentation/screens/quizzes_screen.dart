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
      backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: Query(
        options: QueryOptions(document: gql(kQuizzes), variables: const {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          final quizzes = (result.data?['quizzes'] as List?) ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: dark ? DesignTokens.darkSurface : DesignTokens.surface,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.emoji_events_rounded, size: 18, color: DesignTokens.warning),
                        const SizedBox(width: 8),
                        Text('Challenge Yourself', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      ]),
                      if (quizzes.isNotEmpty)
                        Text('${quizzes.length} quiz${quizzes.length == 1 ? '' : 'zes'} to master',
                          style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textSecondary),
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => refetch?.call(), tooltip: 'Refresh'),
                ],
              ),
              SliverToBoxAdapter(child: _HeroBanner(dark: dark)),
              if (result.isLoading && quizzes.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: ShimmerBox(height: 96, radius: DesignTokens.radiusXl),
                    ), childCount: 8),
                  ),
                )
              else if (result.hasException && quizzes.isEmpty)
                SliverFillRemaining(child: ErrorState(message: 'Could not load quizzes. Check your connection.', onRetry: () => refetch?.call()))
              else if (quizzes.isEmpty)
                SliverFillRemaining(child: _EmptyState())
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

class _HeroBanner extends StatelessWidget {
  final bool dark;
  const _HeroBanner({required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF1B6CA8).withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('TEST YOUR KNOWLEDGE', style: TextStyle(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 3),
          const Text('Master concepts with interactive quizzes', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          const Text('Master each topic', style: TextStyle(color: Colors.white60, fontSize: 11)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white60, size: 14),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: const Icon(Icons.quiz_outlined, size: 40, color: DesignTokens.primary)),
      const SizedBox(height: 16),
      Text('No quizzes yet', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Check back soon.', style: TextStyle(color: DesignTokens.textSecondary), textAlign: TextAlign.center),
    ]));
  }
}


