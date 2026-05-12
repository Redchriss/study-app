import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

class QuizResultsScreen extends ConsumerWidget {
  final String attemptId;
  const QuizResultsScreen({super.key, required this.attemptId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(document: gql(r'''
        query QuizAttempt($id: ID!) {
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
        return Scaffold(
          appBar: AppBar(title: Text('Results'), centerTitle: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    Text('${attempt['score']?.toStringAsFixed(0) ?? '0'}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('$correct/${answers.length} correct', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                    Text('Time: ${attempt['timeDisplay'] ?? 'N/A'}', style: const TextStyle(color: Colors.white60)),
                  ]),
                ),
                const SizedBox(height: 24),
                ...answers.asMap().entries.map((e) {
                  final a = e.value;
                  final correct = a['isCorrect'] == true;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? AppColors.success : AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(a['question']['questionText'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                          ]),
                          if (a['question']['concept'] != null && a['question']['concept'] != '') ...[
                            const SizedBox(height: 8),
                            Chip(label: Text(a['question']['concept'], style: const TextStyle(fontSize: 11))),
                          ],
                          const SizedBox(height: 8),
                          Text('Your answer: ${a['selectedAnswer']?['answerText'] ?? 'N/A'}'),
                          if (!correct) ...[
                            const SizedBox(height: 4),
                            Text('Correct: ${a['correctAnswer']?['answerText'] ?? ''}', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                          if (a['correctAnswer']?['explanation'] != null && a['correctAnswer']['explanation'] != '') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                              child: Text(a['correctAnswer']['explanation'], style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ),
                          ],
                          if (a['question']['explanation'] != null && a['question']['explanation'] != '') ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: Text(a['question']['explanation'], style: const TextStyle(fontSize: 13)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
