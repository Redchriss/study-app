import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'quiz_share_sheet.dart';

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
              message: graphQLErrorMessage(
                  result.exception, 'Failed to load results'),
              onRetry: () => refetch?.call(),
            ),
          );
        }
        final attempt = result.data?['quizAttempt'];
        if (attempt == null)
          return const Scaffold(body: Center(child: Text('Attempt not found')));
        final answers = (attempt['userAnswers'] as List?) ?? [];
        final correct = attempt['correctCount'] ??
            answers.where((a) => a['isCorrect'] == true).length;
        final score = attempt['score']?.toStringAsFixed(0) ?? '0';
        final total = attempt['totalPoints'] ?? answers.length;
        return Scaffold(
          appBar: AppBar(
            title: Text(attempt['quiz']?['title'] ?? 'Results'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => showQuizShareSheet(context, attempt, ref),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            child: Column(children: [
              GlassCard(
                  child: Column(children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [DesignTokens.primary, DesignTokens.accent]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                      child: Text('$score%',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white))),
                ),
                const SizedBox(height: DesignTokens.spMd),
                Text('$correct/$total correct',
                    style: theme.textTheme.titleMedium),
                Text('Time: ${attempt['timeDisplay'] ?? 'N/A'}',
                    style: const TextStyle(
                        color: DesignTokens.textSecondary, fontSize: 13)),
              ])),
              const SizedBox(height: DesignTokens.spLg),
              ...answers.asMap().entries.map((e) {
                final a = e.value;
                final isCorrect = a['isCorrect'] == true;
                final yourAnswer =
                    (a['selectedAnswer'] as Map?)?['answerText'] as String?;
                final correctAnswer =
                    (a['correctAnswer'] as Map?)?['answerText'] as String?;
                return Container(
                  margin: const EdgeInsets.only(bottom: DesignTokens.spSm),
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(
                        color: isCorrect
                            ? DesignTokens.success.withValues(alpha: 0.3)
                            : DesignTokens.error.withValues(alpha: 0.2)),
                    boxShadow: DesignTokens.shadowSm(dark),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                              color: isCorrect
                                  ? DesignTokens.success
                                  : DesignTokens.error,
                              size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text('Question ${e.key + 1}',
                                  style: theme.textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600))),
                        ]),
                        if (!isCorrect && correctAnswer != null) ...[
                          const SizedBox(height: 6),
                          Text('Correct: $correctAnswer',
                              style: const TextStyle(
                                  fontSize: 12, color: DesignTokens.success)),
                        ],
                        if (yourAnswer != null) ...[
                          const SizedBox(height: 2),
                          Text('Your answer: $yourAnswer',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isCorrect
                                      ? DesignTokens.textSecondary
                                      : DesignTokens.error)),
                        ],
                      ]),
                );
              }),
            ]),
          ),
        );
      },
    );
  }
}
