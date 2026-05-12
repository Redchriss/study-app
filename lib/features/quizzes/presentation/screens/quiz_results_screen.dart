import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class QuizResultsScreen extends ConsumerWidget {
  final String attemptId;
  const QuizResultsScreen({super.key, required this.attemptId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(document: gql(r'''
        query QA($id: ID!) {
          quizAttempt(id: $id) {
            id score correctCount timeDisplay
            quiz { title }
            userAnswers {
              isCorrect
              question { questionText concept explanation }
              selectedAnswer { answerText }
              correctAnswer { answerText explanation }
            }
          }
        }
      '''), variables: {'id': attemptId}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final attempt = result.data?['quizAttempt'];
        if (attempt == null) return const Scaffold(body: Center(child: Text('Attempt not found')));
        final answers = (attempt['userAnswers'] as List?) ?? [];
        final correct = answers.where((a) => a['isCorrect'] == true).length;
        final score = attempt['score']?.toStringAsFixed(0) ?? '0';
        return Scaffold(
          appBar: AppBar(title: Text(attempt['quiz']?['title'] ?? 'Results'), centerTitle: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            child: Column(children: [
              GlassCard(child: Column(children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [DesignTokens.primary, DesignTokens.accent]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('$score%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(height: DesignTokens.spMd),
                Text('$correct/${answers.length} correct', style: theme.textTheme.titleMedium),
                Text('Time: ${attempt['timeDisplay'] ?? 'N/A'}', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
              ])),
              const SizedBox(height: DesignTokens.spLg),
              ...answers.asMap().entries.map((e) {
                final a = e.value;
                final correct = a['isCorrect'] == true;
                return Container(
                  margin: const EdgeInsets.only(bottom: DesignTokens.spSm),
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(color: correct ? DesignTokens.success.withValues(alpha: 0.3) : DesignTokens.error.withValues(alpha: 0.2)),
                    boxShadow: DesignTokens.shadowSm(dark),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? DesignTokens.success : DesignTokens.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(a['question']?['questionText'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                    ]),
                    if (a['question']?['concept'] != null && a['question']['concept'] != '') ...[
                      const SizedBox(height: 8),
                      Chip(label: Text(a['question']['concept'], style: const TextStyle(fontSize: 11))),
                    ],
                    const SizedBox(height: 6),
                    Text('Your answer: ${a['selectedAnswer']?['answerText'] ?? 'N/A'}'),
                    if (!correct) ...[
                      const SizedBox(height: 4),
                      Text('Correct: ${a['correctAnswer']?['answerText'] ?? ''}', style: TextStyle(color: DesignTokens.success, fontWeight: FontWeight.w600)),
                    ],
                    if (a['correctAnswer']?['explanation'] != null && a['correctAnswer']['explanation'] != '') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: DesignTokens.success.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                        child: Text(a['correctAnswer']['explanation'], style: const TextStyle(fontSize: 13, color: DesignTokens.textSecondary)),
                      ),
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
