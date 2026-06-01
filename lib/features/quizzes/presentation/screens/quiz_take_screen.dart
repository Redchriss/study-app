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
import 'quiz_progress_bar.dart';

class QuizTakeScreen extends ConsumerStatefulWidget {
  final String slug;
  const QuizTakeScreen({super.key, required this.slug});
  @override
  ConsumerState<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends ConsumerState<QuizTakeScreen> {
  final Map<String, String?> _answers = {};
  final Map<String, bool> _results = {};
  int _time = 0;
  String? _attemptId;
  bool _submitting = false;
  bool _startingAttempt = false;
  Timer? _timer;
  bool _paused = false;
  bool _resumeChecked = false;
  int _currentIndex = 0;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryRestoreSession());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageCtrl.dispose();
    _persistState();
    super.dispose();
  }

  void _tick() {
    if (!mounted || _submitting || _paused) return;
    setState(() => _time++);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
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
        content: const Text('You have a partial attempt. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Fresh Start')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Resume')),
        ],
      ),
    );
    if (!mounted) return;
    if (resume == true) {
      final rawAnswers = saved['answers'] as Map? ?? {};
      final restored = rawAnswers.map<String, String?>(
          (k, v) => MapEntry(k.toString(), v?.toString()));
      restored.removeWhere((_, v) => v == null || v.isEmpty);
      final restoredAttemptId = saved['attemptId'] as String?;
      final restoredTime = saved['time'] as int? ?? 0;
      setState(() {
        _answers.addAll(restored);
        _time = restoredTime;
        if (restoredAttemptId != null && restoredAttemptId.isNotEmpty) {
          _attemptId = restoredAttemptId;
        }
      });
      _startTimer();
    } else {
      HiveService.clearQuizAttempt(widget.slug);
    }
  }

  void _onAnswer(String qId, String optId) {
    setState(() {
      _answers[qId] = optId;
    });
    HiveService.saveQuizAttempt(widget.slug,
        answers: _answers, time: _time, attemptId: _attemptId);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(graphQLErrorMessage(
                  result.exception, 'Could not start quiz.')),
              backgroundColor: DesignTokens.error),
        );
        return;
      }
      setState(() => _attemptId = attemptId);
      _persistState();
      _startTimer();
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
              if (e.value != null) 'selectedAnswerId': e.value
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
      if (!mounted) return;
      setState(() => _submitting = false);
      if (result.hasException) {
        if (result.exception?.linkException != null) {
          HiveService.enqueueQuizSubmission({
            'attemptId': _attemptId,
            'answers': answers,
            'timeTakenSeconds': _time
          });
          HiveService.clearQuizAttempt(widget.slug);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Saved offline — will submit when connected'),
                backgroundColor: DesignTokens.warning));
          }
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(graphQLErrorMessage(result.exception, 'Submit failed')),
            backgroundColor: DesignTokens.error));
        return;
      }
      final submitted = result.data?['submitQuizAttempt'];
      final aId = submitted?['attempt']?['id'] as String?;
      if (submitted?['success'] == true && aId != null && aId.isNotEmpty) {
        HiveService.clearQuizAttempt(widget.slug);
        if (mounted) context.pushReplacement('/quiz-results/$aId');
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(submitted?['errors']?.first?.toString() ?? 'Submit failed'),
          backgroundColor: DesignTokens.error));
    } catch (e) {
      HiveService.enqueueQuizSubmission({
        'attemptId': _attemptId,
        'answers': answers,
        'timeTakenSeconds': _time
      });
      HiveService.clearQuizAttempt(widget.slug);
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Saved offline — will retry'),
            backgroundColor: DesignTokens.warning));
      }
    }
  }

  void _onNext() {
    if (_currentIndex < _totalQuestions - 1) {
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      setState(() => _currentIndex++);
    }
  }

  int get _totalQuestions => 0;
  int get _answeredCount =>
      _answers.values.where((v) => v != null && v.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options:
          QueryOptions(document: gql(kQuiz), variables: {'slug': widget.slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: LoadingWidget());
        if (result.hasException) {
          return Scaffold(
              body: ErrorState(
                  message: graphQLErrorMessage(
                      result.exception, 'Failed to load quiz'),
                  onRetry: () => refetch?.call()));
        }
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
            if (mounted) _startAttempt(quizId, ref.read(graphqlClientProvider));
          });
        }
        final answered = _answeredCount;

        return Scaffold(
          backgroundColor:
              dark ? DesignTokens.darkBackground : DesignTokens.background,
          appBar: AppBar(
            backgroundColor:
                dark ? DesignTokens.darkSurface : DesignTokens.surface,
            title: Text(quiz['title'] ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15)),
            centerTitle: true,
            actions: [QuizTimerWidget(seconds: _time)],
          ),
          body: Column(
            children: [
              AchievementProgressBar(
                answered: answered,
                total: questions.length,
                score: _results.values.where((v) => v).length,
              ),
              if (HiveService.hasPendingQuizSubmissions()) _OfflineBanner(),
              Expanded(
                child: questions.isEmpty
                    ? const Center(child: Text('No questions'))
                    : PageView.builder(
                        controller: _pageCtrl,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: questions.length,
                        onPageChanged: (i) => setState(() => _currentIndex = i),
                        itemBuilder: (_, i) {
                          final q = questions[i] as Map<String, dynamic>;
                          final qId = q['id'] as String? ?? '$i';
                          final answeredId = _answers[qId];
                          final isCorrect = _results[qId];
                          return QuizQuestionCard(
                            index: i,
                            questionId: qId,
                            questionText: q['questionText'] ?? '',
                            questionType: q['questionType']?.toString(),
                            options: (q['answers'] as List?) ?? [],
                            selectedAnswerId: answeredId,
                            showFeedback: answeredId != null,
                            isCorrect: isCorrect,
                            onSelect: (optId) {
                              _onAnswer(qId, optId);
                              setState(() {});
                            },
                          );
                        },
                      ),
              ),
              _BottomBar(
                currentIndex: _currentIndex,
                total: questions.length,
                answered: answered,
                attemptId: _attemptId,
                submitting: _submitting,
                hasAnswers: _answers.isNotEmpty,
                onSubmit: () => _submit(ref.read(graphqlClientProvider)),
                onNext: _onNext,
                dark: dark,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          '${HiveService.pendingQuizCount()} pending — will retry',
          style: const TextStyle(fontSize: 12, color: DesignTokens.warning),
        )),
      ]),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final int answered;
  final String? attemptId;
  final bool submitting;
  final bool hasAnswers;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final bool dark;

  const _BottomBar({
    required this.currentIndex,
    required this.total,
    required this.answered,
    this.attemptId,
    required this.submitting,
    required this.hasAnswers,
    required this.onSubmit,
    required this.onNext,
    required this.dark,
  });

  bool get _isLast => currentIndex >= total - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        border: Border(
            top: BorderSide(
                color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                    .withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          if (!_isLast)
            Text('${currentIndex + 1}/$total',
                style:
                    TextStyle(color: DesignTokens.textTertiary, fontSize: 13))
          else
            Text('Review',
                style:
                    TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
          const Spacer(),
          SizedBox(
            width: _isLast ? double.infinity : null,
            child: FilledButton(
              onPressed: _isLast
                  ? (attemptId == null || submitting || !hasAnswers
                      ? null
                      : onSubmit)
                  : onNext,
              child: _isLast
                  ? (submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Submit ($answered/$total)'))
                  : const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}
