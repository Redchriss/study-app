import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'quiz_share_sheet.dart';
import 'quiz_results_score_gauge.dart';
import 'quiz_results_performance_row.dart';
import 'quiz_results_answer_review_card.dart';

class QuizResultsScreen extends ConsumerWidget {
  final String attemptId;
  const QuizResultsScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
          document: gql(kQuizAttempt), variables: {'id': attemptId}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: LoadingWidget());
        if (result.hasException) {
          return Scaffold(
              body: ErrorState(
            message:
                graphQLErrorMessage(result.exception, 'Failed to load results'),
            onRetry: () => refetch?.call(),
          ));
        }
        final attempt = result.data?['quizAttempt'];
        if (attempt == null)
          return const Scaffold(body: Center(child: Text('Attempt not found')));
        final answers = (attempt['userAnswers'] as List?) ?? [];
        final correct = attempt['correctCount'] ??
            answers.where((a) => a['isCorrect'] == true).length;
        final score = attempt['score']?.toStringAsFixed(0) ?? '0';
        final total = attempt['totalPoints'] ?? answers.length;
        final pct = (correct / (total > 0 ? total : 1)).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor:
              dark ? DesignTokens.darkBackground : DesignTokens.background,
          appBar: AppBar(
            backgroundColor:
                dark ? DesignTokens.darkSurface : DesignTokens.surface,
            title: Text(attempt['quiz']?['title'] ?? 'Results',
                style: const TextStyle(fontSize: 15)),
            centerTitle: true,
            actions: [
              IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => showQuizShareSheet(context, attempt, ref)),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: QuizResultsScoreGauge(
                      pct: pct,
                      correct: correct,
                      total: total,
                      score: score,
                      dark: dark)),
              SliverToBoxAdapter(
                  child: QuizResultsPerformanceRow(
                      correct: correct,
                      total: total,
                      timeDisplay: attempt['timeDisplay']?.toString(),
                      dark: dark)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Question Review',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => QuizResultsAnswerReviewCard(
                      index: i,
                      answer: answers[i] as Map<String, dynamic>,
                      dark: dark,
                    ),
                    childCount: answers.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
