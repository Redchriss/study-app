import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'quiz_answer_widgets.dart';

class QuizTakeScreen extends ConsumerStatefulWidget {
  final String slug;
  const QuizTakeScreen({super.key, required this.slug});
  @override
  ConsumerState<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends ConsumerState<QuizTakeScreen>
    with WidgetsBindingObserver {
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
  int _totalQuestions = 0;
  late PageController _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryRestoreSession());
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      setState(() => _paused = true);
      _persistState();
    } else if (state == AppLifecycleState.resumed) {
      setState(() => _paused = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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

  int get _answeredCount =>
      _answers.values.where((v) => v != null && v.isNotEmpty).length;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Query(
      options:
          QueryOptions(document: gql(kQuiz), variables: {'slug': widget.slug}),
      builder: (result, {fetchMore, refetch}) {
        if (result.data != null) {
          final quizData = result.data?['quiz'];
          if (quizData != null) {
            final qs = (quizData['questions'] as List?) ?? [];
            if (_totalQuestions != qs.length) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _totalQuestions = qs.length);
              });
            }
          }
        }
        return QuizBody(
          result: result,
          refetch: refetch,
          answers: _answers,
          results: _results,
          time: _time,
          attemptId: _attemptId,
          submitting: _submitting,
          startingAttempt: _startingAttempt,
          currentIndex: _currentIndex,
          answeredCount: _answeredCount,
          pageCtrl: _pageCtrl,
          dark: dark,
          onAnswer: _onAnswer,
          onNext: _onNext,
          onSubmit: () => _submit(ref.read(graphqlClientProvider)),
          onStartAttempt: (quizId) =>
              _startAttempt(quizId, ref.read(graphqlClientProvider)),
          onPageChanged: (i) => setState(() => _currentIndex = i),
        );
      },
    );
  }
}
