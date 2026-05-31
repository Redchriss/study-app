import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/hive_service.dart';
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
  bool _resumeChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryRestoreSession());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _persistState();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _paused = true;
      _persistState();
    } else if (state == AppLifecycleState.resumed && _paused) {
      _paused = false;
    }
  }

  void _persistState() {
    if (_answers.isNotEmpty) {
      HiveService.saveQuizAttempt(
        widget.slug,
        answers: _answers,
        time: _time,
        attemptId: _attemptId,
      );
    }
  }

  Future<void> _tryRestoreSession() async {
    if (_resumeChecked || !mounted) return;
    _resumeChecked = true;
    final saved = HiveService.getSavedQuizAttempt(widget.slug);
    if (saved == null || !mounted) return;

    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resume Quiz?'),
        content: const Text(
          'You have a partially completed quiz. Continue where you left off?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Start Fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resume'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      final rawAnswers = saved['answers'] as Map? ?? {};
      final restoredAnswers = rawAnswers.map<String, String?>(
        (k, v) => MapEntry(k.toString(), v?.toString()),
      );
      restoredAnswers.removeWhere((_, v) => v == null || v.isEmpty);
      final restoredAttemptId = saved['attemptId'] as String?;
      final restoredTime = saved['time'] as int? ?? 0;
      setState(() {
        _answers.addAll(restoredAnswers);
        _time = restoredTime;
        if (restoredAttemptId != null && restoredAttemptId.isNotEmpty) {
          _attemptId = restoredAttemptId;
        }
      });
    } else {
      HiveService.clearQuizAttempt(widget.slug);
    }
  }

  void _tick() {
    if (!mounted || _submitting || _paused || _timer == null) return;
    setState(() => _time++);
  }

  void _onAnswer(String qId, String? optId) {
    setState(() => _answers[qId] = optId);
    HiveService.saveQuizAttempt(
      widget.slug,
      answers: _answers,
      time: _time,
      attemptId: _attemptId,
    );
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
        final message =
            graphQLErrorMessage(result.exception, 'Could not start quiz.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: DesignTokens.error),
        );
        return;
      }
      setState(() => _attemptId = attemptId);
      _persistState();
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
          if (_isNetworkError(result.exception)) {
            HiveService.enqueueQuizSubmission({
              'attemptId': _attemptId,
              'answers': answers,
              'timeTakenSeconds': _time,
            });
            HiveService.clearQuizAttempt(widget.slug);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Submission saved — will retry when connected'),
                backgroundColor: DesignTokens.warning,
              ),
            );
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(graphQLErrorMessage(result.exception, 'Submit failed')),
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
          HiveService.clearQuizAttempt(widget.slug);
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
      HiveService.enqueueQuizSubmission({
        'attemptId': _attemptId,
        'answers': answers,
        'timeTakenSeconds': _time,
      });
      HiveService.clearQuizAttempt(widget.slug);
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission saved — will retry when connected'),
            backgroundColor: DesignTokens.warning,
          ),
        );
      }
    }
  }

  bool _isNetworkError(OperationException? e) {
    if (e == null) return false;
    return e.linkException != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options:
          QueryOptions(document: gql(kQuiz), variables: {'slug': widget.slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return const Scaffold(body: LoadingWidget());
        }
        if (result.hasException) {
          return Scaffold(
            body: ErrorState(
              message:
                  graphQLErrorMessage(result.exception, 'Failed to load quiz'),
              onRetry: () => refetch?.call(),
            ),
          );
        }
        final quiz = result.data?['quiz'];
        if (quiz == null) {
          return const Scaffold(body: Center(child: Text('Quiz not found')));
        }
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
            if (HiveService.hasPendingQuizSubmissions())
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DesignTokens.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.cloud_upload_outlined,
                      size: 16, color: DesignTokens.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${HiveService.pendingQuizCount()} submission${HiveService.pendingQuizCount() == 1 ? '' : 's'} pending — will retry when connected.',
                      style: const TextStyle(
                          fontSize: 12, color: DesignTokens.warning),
                    ),
                  ),
                ]),
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
                    onSelect: (optId) => _onAnswer(qId, optId),
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
