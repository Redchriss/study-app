import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
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
  bool _startedAttempt = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), _tick);
  }

  @override
  void dispose() {
    _time = 0;
    super.dispose();
  }

  void _tick() {
    if (!mounted || _submitting) return;
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
    if (result.data?['submitQuizAttempt']?['success'] == true && mounted) {
      context.go('/quiz-results/${result.data!['submitQuizAttempt']['attempt']['id']}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
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
            if (!_startedAttempt) {
              _startedAttempt = true;
              runMutation({'quizId': quiz['id']});
              final resultData = mutResult?.data;
              if (resultData != null) _attemptId = resultData['startQuizAttempt']['attempt']['id'];
            }
            final mins = _time ~/ 60;
            final secs = _time % 60;
            final answered = _answers.length;
            return Scaffold(
              appBar: AppBar(
                title: Text(quiz['title'] ?? '', overflow: TextOverflow.ellipsis),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DesignTokens.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: DesignTokens.primary),
                    ),
                  ),
                ],
              ),
              body: Column(children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(DesignTokens.spMd),
                    itemCount: questions.length,
                    itemBuilder: (_, i) {
                      final q = questions[i];
                      final answers = (q['answers'] as List?) ?? [];
                      return Container(
                        margin: const EdgeInsets.only(bottom: DesignTokens.spSm),
                        padding: const EdgeInsets.all(DesignTokens.spMd),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                          boxShadow: DesignTokens.shadowSm(dark),
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
                              child: Center(child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                            ),
                            const SizedBox(width: DesignTokens.spSm),
                            Expanded(child: Text(q['questionText'] ?? '', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                          ]),
                          const SizedBox(height: DesignTokens.spSm),
                          ...answers.map((a) {
                            final id = a['id'] as String;
                            final selected = _answers[q['id']] == id;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: DesignTokens.spXs),
                              child: AnimatedPress(
                                onTap: () => setState(() => _answers[q['id']] = id),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spSm),
                                  decoration: BoxDecoration(
                                    color: selected ? DesignTokens.primary.withValues(alpha: 0.08) : null,
                                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                    border: Border.all(
                                      color: selected ? DesignTokens.primary.withValues(alpha: 0.3) : (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Row(children: [
                                    Container(
                                      width: 22, height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: selected ? DesignTokens.primary : DesignTokens.textTertiary, width: 2),
                                      ),
                                      child: selected ? Center(child: Container(
                                        width: 12, height: 12,
                                        decoration: const BoxDecoration(color: DesignTokens.primary, shape: BoxShape.circle),
                                      )) : null,
                                    ),
                                    const SizedBox(width: DesignTokens.spSm),
                                    Text(a['answerText'] ?? '', style: TextStyle(color: selected ? DesignTokens.primary : null)),
                                  ]),
                                ),
                              ),
                            );
                          }),
                        ]),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.spSm),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_submitting || _attemptId == null) ? null : () {
                          _submit(quiz['id'], ref.read(graphqlClientProvider));
                        },
                        child: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text('Submit ($answered/${questions.length})'),
                      ),
                    ),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }
}
