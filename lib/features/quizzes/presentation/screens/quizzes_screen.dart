import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Quizzes', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: Query(
        options: QueryOptions(document: gql(kQuizzes), variables: const {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          if (result.hasException) {
          return ErrorState(message: 'Could not load. Check your connection.', onRetry: () => refetch?.call());
          }
          if (result.isLoading) {
            return ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              itemCount: 8, itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: DesignTokens.spSm),
                child: ShimmerBox(height: 80, radius: DesignTokens.radiusLg),
              ),
            );
          }
          final quizzes = (result.data?['quizzes'] as List?) ?? [];
          if (quizzes.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.quiz_outlined, size: 80, color: DesignTokens.textTertiary.withValues(alpha: 0.5)),
            const SizedBox(height: DesignTokens.spMd),
            Text('No quizzes yet', style: theme.textTheme.titleMedium),
          ]));
          }
          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: ListView.builder(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              itemCount: quizzes.length,
              itemBuilder: (_, i) {
                final q = quizzes[i];
                final diffColor = q['difficulty'] == 'easy' ? DesignTokens.success : q['difficulty'] == 'hard' ? DesignTokens.error : DesignTokens.warning;
                return Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spSm),
                  child: AnimatedPress(
                    onTap: () => context.go('/quiz/${q['slug']}'),
                    child: Container(
                      padding: const EdgeInsets.all(DesignTokens.spMd),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                        border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                        boxShadow: DesignTokens.shadowSm(dark),
                      ),
                      child: Row(children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                          child: const Icon(Icons.quiz_outlined, color: DesignTokens.primary, size: 22),
                        ),
                        const SizedBox(width: DesignTokens.spMd),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(q['title'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('${q['subject']?['name'] ?? ''}  ·  ${q['durationMinutes'] ?? '?'} min', style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary)),
                          ],
                        )),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: diffColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignTokens.radiusXl)),
                          child: Text('${q['questionCount'] ?? 0} Q', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: diffColor)),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
