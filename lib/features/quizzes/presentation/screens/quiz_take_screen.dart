import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'quiz_question_card.dart';
import 'quiz_timer_widget.dart';

class QuizTakeScreen extends ConsumerStatefulWidget {
  final String slug;
  const QuizTakeScreen({super.key, required this.slug});
  @override
  ConsumerState<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends ConsumerState<QuizTakeScreen>
    with WidgetsBindingObserver {
  final Map<String, String?> _answers = {};
  int _time = 0;
  String? _attemptId;
  bool _submitting = false;
  bool _startingAttempt = false;
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
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _paused = true;
    } else if (state == AppLifecycleState.resumed && _paused) {
      _paused = false;
    }
  }

  void _tick() {
    if (!mounted || _submitting || _paused || _timer == null) return;
    setState(() => _time++);
  }

  Future<void> _startAttempt(String quizId, GraphQLClient client) async {
    if (_startingAttempt || _attemptId != null) return;
    _startingAttempt = true;
    try {
      final result = await client.mutate(MutationOptions(
        document: gql(kStartQuizAttempt),
        variables: {'quizId': quizId},
      ));
      if (!mounted) return;
      final attemptId =
          result.data?['startQuizAttempt']?['attempt']?['id'] as String?;
      if (attemptId == null || attemptId.isEmpty) {
        final message = graphQLErrorMessage(result.exception, 'Could not start quiz.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
        );
        return;
      }
      setState(() => _attemptId = attemptId);
    } finally {
      _startingAttempt = false;
    }
  }

  Future<void> _submit(GraphQLClient client) async {
    if (_submitting || _attemptId == null) return;
    setState(() => _submitting = true);
    final answers = _answers.entries
        .map((e) => {
              'questionId': e.key,
              if (e.value != null) 'selectedAnswerId': e.value,
            })
        .toList();
    try {
      final result = await client.mutate(MutationOptions(
        document: gql(kSubmitQuizAttempt),
        variables: {
          'attemptId': _attemptId,
          'answers': answers,
          'timeTakenSeconds': _time
        },
      ));
      if (mounted) {
        setState(() => _submitting = false);
        if (result.hasException) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  graphQLErrorMessage(result.exception, 'Submit failed')),
              backgroundColor: DesignTokens.error,
            ),
          );
          return;
        }
        final submitted = result.data?['submitQuizAttempt'];
        final attemptId = submitted?['attempt']?['id'] as String?;
        if (submitted?['success'] == true &&
            attemptId != null &&
            attemptId.isNotEmpty) {
          context.pushReplacement('/quiz-results/$attemptId');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                (submitted?['errors'] as List?)?.firstOrNull?.toString() ??
                    'Submit failed'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: DesignTokens.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options:
          QueryOptions(document: gql(kQuiz), variables: {'slug': widget.slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading)
          return const Scaffold(
              body: LoadingWidget());
        if (result.hasException)
          return Scaffold(
            body: ErrorState(
              message: graphQLErrorMessage(result.exception, 'Failed to load quiz'),
              onRetry: () => refetch?.call(),
            ),
          );
        final quiz = result.data?['quiz'];
        if (quiz == null)
          return const Scaffold(body: Center(child: Text('Quiz not found')));
        final questions = (quiz['questions'] as List?) ?? [];
        final quizId = quiz['id'] as String?;
        if (quizId != null &&
            quizId.isNotEmpty &&
            _attemptId == null &&
            !_startingAttempt) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _startAttempt(quizId, ref.read(graphqlClientProvider));
            }
          });
        }
        final answered = _answers.length;
        return Scaffold(
          appBar: AppBar(
            title: Text(quiz['title'] ?? '', overflow: TextOverflow.ellipsis),
            actions: [
              QuizTimerWidget(seconds: _time),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(children: [
                Text('$answered/${questions.length} answered',
                    style: theme.textTheme.bodySmall),
                const Spacer(),
                Text(
                    '${(answered / (questions.isEmpty ? 1 : questions.length) * 100).round()}%',
                    style: theme.textTheme.bodySmall),
              ]),
            ),
            if (questions.isNotEmpty)
              LinearProgressIndicator(
                value: answered / questions.length,
                backgroundColor:
                    dark ? DesignTokens.surfaceVariant : DesignTokens.border,
                color: answered == questions.length
                    ? DesignTokens.success
                    : DesignTokens.primary,
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
                  return QuizQuestionCard(
                    index: i,
                    questionId: qId,
                    questionText: q['questionText'] ?? '',
                    options: (q['answers'] as List?) ?? [],
                    selectedAnswerId: _answers[qId],
                    onSelect: (optId) => setState(() => _answers[qId] = optId),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (_submitting || _attemptId == null || answered == 0)
                          ? null
                          : () {
                              _submit(ref.read(graphqlClientProvider));
                            },
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Submit ($answered/${questions.length})'),
                ),
              ),
            ),
          ]),
        );
      },
    );
  }
}
