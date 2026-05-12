import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class QuizTakeScreen extends ConsumerStatefulWidget {
  final String slug;
  const QuizTakeScreen({super.key, required this.slug});
  @override
  ConsumerState<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends ConsumerState<QuizTakeScreen> {
  final Map<String, String?> _answers = {};
  int _time = 0;
  String? _attemptId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), _tick);
  }

  void _tick() {
    if (!mounted) return;
    setState(() => _time++);
    Future.delayed(const Duration(seconds: 1), _tick);
  }

  Future<void> _submit(String quizId, GraphQLClient client) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final answers = _answers.entries.map((e) => {
      'questionId': e.key,
      if (e.value != null) 'selectedAnswerId': e.value,
    }).toList();
    final result = await client.mutate(MutationOptions(
      document: gql(kSubmitQuizAttempt),
      variables: {'attemptId': _attemptId, 'answers': answers, 'timeTakenSeconds': _time},
    ));
    setState(() => _submitting = false);
    if (result.hasException || result.data?['submitQuizAttempt'] == null) return;
    final data = result.data!['submitQuizAttempt'];
    if (data['success'] == true && mounted) {
      context.go('/quiz-results/${data['attempt']['id']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Query(
      options: QueryOptions(document: gql(kQuiz), variables: {'slug': widget.slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final quiz = result.data?['quiz'];
        if (quiz == null) return const Scaffold(body: Center(child: Text('Quiz not found')));
        final questions = (quiz['questions'] as List?) ?? [];
        return Mutation(
          options: MutationOptions(document: gql(kStartQuizAttempt)),
          builder: (runMutation, mutResult) {
            if (_attemptId == null) {
              runMutation({'quizId': quiz['id']});
              final resultData = mutResult?.data;
              if (resultData != null) {
                _attemptId = resultData['startQuizAttempt']['attempt']['id'];
              }
            }
            final mins = _time ~/ 60;
            final secs = _time % 60;
            return Scaffold(
              appBar: AppBar(
                title: Text(quiz['title'] ?? '', overflow: TextOverflow.ellipsis),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text('${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    child: Mutation(
                      options: MutationOptions(document: gql(kSubmitQuizAttempt)),
                      builder: (submitFn, _) => ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: questions.length,
                        itemBuilder: (_, i) {
                          final q = questions[i];
                          final answers = (q['answers'] as List?) ?? [];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    CircleAvatar(radius: 14, child: Text('${i + 1}', style: const TextStyle(fontSize: 12))),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(q['questionText'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                                  ]),
                                  const SizedBox(height: 12),
                                  ...answers.map((a) => RadioListTile<String?>(
                                    value: a['id'],
                                    groupValue: _answers[q['id']],
                                    title: Text(a['answerText'] ?? ''),
                                    onChanged: (v) => setState(() => _answers[q['id']] = v),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  )),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : () async {
                            final client = ref.read(graphqlClientProvider).valueOrNull;
                            if (client != null) _submit(quiz['id'], client);
                          },
                          child: _submitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Submit (${_answers.length}/${questions.length})'),
                        ),
                      ),
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
