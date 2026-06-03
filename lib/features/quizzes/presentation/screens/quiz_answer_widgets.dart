import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/services/hive_service.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'quiz_question_card.dart';
import 'quiz_progress_bar.dart';
import 'quiz_timer_widget.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

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

class BottomBar extends StatelessWidget {
  final int currentIndex;
  final int total;
  final int answered;
  final String? attemptId;
  final bool submitting;
  final bool hasAnswers;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final bool dark;

  const BottomBar({
    super.key,
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

class QuizBody extends StatelessWidget {
  final QueryResult result;
  final VoidCallback? refetch;
  final Map<String, String?> answers;
  final Map<String, bool> results;
  final int time;
  final String? attemptId;
  final bool submitting;
  final bool startingAttempt;
  final int currentIndex;
  final int answeredCount;
  final PageController pageCtrl;
  final bool dark;
  final void Function(String qId, String optId) onAnswer;
  final VoidCallback onSubmit;
  final VoidCallback onNext;
  final void Function(String quizId) onStartAttempt;
  final ValueChanged<int> onPageChanged;

  const QuizBody({
    super.key,
    required this.result,
    this.refetch,
    required this.answers,
    required this.results,
    required this.time,
    this.attemptId,
    required this.submitting,
    required this.startingAttempt,
    required this.currentIndex,
    required this.answeredCount,
    required this.pageCtrl,
    required this.dark,
    required this.onAnswer,
    required this.onSubmit,
    required this.onNext,
    required this.onStartAttempt,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (result.isLoading) return const Scaffold(body: LoadingWidget());
    if (result.hasException) {
      return Scaffold(
          body: ErrorState(
              message:
                  graphQLErrorMessage(result.exception, 'Failed to load quiz'),
              onRetry: () => refetch?.call()));
    }
    final quiz = result.data?['quiz'];
    if (quiz == null) {
      return const Scaffold(body: Center(child: Text('Quiz not found')));
    }
    final questions = (quiz['questions'] as List?) ?? [];
    final quizId = quiz['id'] as String?;
    if (quizId != null &&
        quizId.isNotEmpty &&
        attemptId == null &&
        !startingAttempt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) onStartAttempt(quizId);
      });
    }
    final answered = answeredCount;

    return Scaffold(
      backgroundColor:
          dark ? DesignTokens.darkBackground : DesignTokens.background,
      appBar: AppBar(
        backgroundColor: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        title: Text(quiz['title'] ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15)),
        centerTitle: true,
        actions: [QuizTimerWidget(seconds: time)],
      ),
      body: Column(
        children: [
          AchievementProgressBar(
            answered: answered,
            total: questions.length,
            score: results.values.where((v) => v).length,
          ),
          if (HiveService.hasPendingQuizSubmissions()) const OfflineBanner(),
          Expanded(
            child: questions.isEmpty
                ? const Center(child: Text('No questions'))
                : PageView.builder(
                    controller: pageCtrl,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    onPageChanged: onPageChanged,
                    itemBuilder: (_, i) {
                      final q = questions[i] as Map<String, dynamic>;
                      final qId = q['id'] as String? ?? '$i';
                      final answeredId = answers[qId];
                      final isCorrect = results[qId];
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
                          onAnswer(qId, optId);
                        },
                      );
                    },
                  ),
          ),
          BottomBar(
            currentIndex: currentIndex,
            total: questions.length,
            answered: answered,
            attemptId: attemptId,
            submitting: submitting,
            hasAnswers: answers.isNotEmpty,
            onSubmit: onSubmit,
            onNext: onNext,
            dark: dark,
          ),
        ],
      ),
    );
  }
}
