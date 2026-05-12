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

class _QuizTakeScreenState extends ConsumerState<QuizTakeScreen> with WidgetsBindingObserver {
  final Map<String, String?> _answers = {};
  int _time = 0;
  String? _attemptId;
  bool _submitting = false;
  bool _startedAttempt = false;
  Timer? _timer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _paused = true;
    } else if (state == AppLifecycleState.resumed && _paused) {
      _paused = false;
    }
  }

  void _tick() {
    if (!mounted || _submitting || _paused || _timer == null) return;
    setState(() => _time++);
  }

  Future<void> _submit(String quizId, GraphQLClient client) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final answers = _answers.entries.map((e) => {
      'questionId': e.key,
      if (e.value != null) 'selectedAnswerId': e.value,
    }).toList();
    try {
      final result = await client.mutate(MutationOptions(
        document: gql(kSubmitQuizAttempt),
        variables: {'attemptId': _attemptId, 'answers': answers, 'timeTakenSeconds': _time},
      ));
      if (mounted) {
        setState(() => _submitting = false);
        if (result.hasException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.exception?.graphqlErrors.first.message ?? 'Submit failed'), backgroundColor: DesignTokens.error),
          );
          return;
        }
        if (result.data?['submitQuizAttempt']?['success'] == true) {
          context.go('/quiz-results/${result.data!['submitQuizAttempt']['attempt']['id']}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: DesignTokens.error),
        );
      }
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
                      color: dark ? DesignTokens.warning.withValues(alpha: 0.15) : DesignTokens.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.timer, size: 16, color: DesignTokens.warning),
                      const SizedBox(width: 4),
                      Text('${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}', style: TextStyle(fontWeight: FontWeight.w600, color: DesignTokens.warning)),
                    ]),
                  ),
                ],
              ),
              body: Column(children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Text('$answered/${questions.length} answered', style: theme.textTheme.bodySmall),
                    const Spacer(),
                    Text('${(answered / (questions.length == 0 ? 1 : questions.length) * 100).round()}%', style: theme.textTheme.bodySmall),
                  ]),
                ),
                if (questions.isNotEmpty)
                  LinearProgressIndicator(
                    value: answered / questions.length,
                    backgroundColor: dark ? DesignTokens.surfaceVariant : DesignTokens.border,
                    color: answered == questions.length ? DesignTokens.success : DesignTokens.primary,
                    minHeight: 4,
                  ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: questions.length,
                    itemBuilder: (_, i) {
                      final q = questions[i] as Map<String, dynamic>;
                      final qId = q['id'] as String? ?? '$i';
                      final options = (q['answers'] as List?) ?? [];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Q${i + 1}. ${q['questionText'] ?? ''}', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 12),
                            ...options.map((opt) {
                              final optId = opt['id'] as String? ?? '';
                              final selected = _answers[qId] == optId;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: InkWell(
                                  onTap: () => setState(() => _answers[qId] = optId),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: selected ? DesignTokens.primary : DesignTokens.border),
                                      borderRadius: BorderRadius.circular(12),
                                      color: selected ? DesignTokens.primary.withValues(alpha: 0.08) : null,
                                    ),
                                    child: Row(children: [
                                      Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, size: 20, color: selected ? DesignTokens.primary : DesignTokens.textTertiary),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(opt['answerText'] ?? '', style: theme.textTheme.bodyMedium)),
                                    ]),
                                  ),
                                ),
                              );
                            }),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_submitting || _attemptId == null || answered == 0) ? null : () {
                        _submit(quiz['id'], ref.read(graphqlClientProvider));
                      },
                      child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Submit ($answered/${questions.length})'),
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
