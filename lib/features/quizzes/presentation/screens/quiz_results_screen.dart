import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/widgets/widgets.dart';
import 'quiz_share_sheet.dart';

class QuizResultsScreen extends ConsumerWidget {
  final String attemptId;
  const QuizResultsScreen({super.key, required this.attemptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(
          document: gql(kQuizAttempt), variables: {'id': attemptId}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: LoadingWidget());
        if (result.hasException) {
          return Scaffold(
              body: ErrorState(
            message:
                graphQLErrorMessage(result.exception, 'Failed to load results'),
            onRetry: () => refetch?.call(),
          ));
        }
        final attempt = result.data?['quizAttempt'];
        if (attempt == null)
          return const Scaffold(body: Center(child: Text('Attempt not found')));
        final answers = (attempt['userAnswers'] as List?) ?? [];
        final correct = attempt['correctCount'] ??
            answers.where((a) => a['isCorrect'] == true).length;
        final score = attempt['score']?.toStringAsFixed(0) ?? '0';
        final total = attempt['totalPoints'] ?? answers.length;
        final pct = (correct / (total > 0 ? total : 1)).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor:
              dark ? DesignTokens.darkBackground : DesignTokens.background,
          appBar: AppBar(
            backgroundColor:
                dark ? DesignTokens.darkSurface : DesignTokens.surface,
            title: Text(attempt['quiz']?['title'] ?? 'Results',
                style: const TextStyle(fontSize: 15)),
            centerTitle: true,
            actions: [
              IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () => showQuizShareSheet(context, attempt, ref)),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: _ScoreGauge(
                      pct: pct,
                      correct: correct,
                      total: total,
                      score: score,
                      dark: dark)),
              SliverToBoxAdapter(
                  child: _PerformanceRow(
                      correct: correct,
                      total: total,
                      timeDisplay: attempt['timeDisplay']?.toString(),
                      dark: dark)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('Question Review',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _AnswerReviewCard(
                      index: i,
                      answer: answers[i] as Map<String, dynamic>,
                      dark: dark,
                    ),
                    childCount: answers.length,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScoreGauge extends StatelessWidget {
  final double pct;
  final int correct;
  final int total;
  final String score;
  final bool dark;
  const _ScoreGauge(
      {required this.pct,
      required this.correct,
      required this.total,
      required this.score,
      required this.dark});

  Color get _gradeColor {
    if (pct >= 0.9) return DesignTokens.success;
    if (pct >= 0.7) return DesignTokens.primary;
    if (pct >= 0.5) return DesignTokens.warning;
    return DesignTokens.error;
  }

  String get _gradeLabel {
    if (pct >= 0.9) return 'Excellent';
    if (pct >= 0.7) return 'Good';
    if (pct >= 0.5) return 'Keep trying';
    return 'Needs work';
  }

  String get _gradeEmoji {
    if (pct >= 0.9) return '\u{1F3C6}';
    if (pct >= 0.7) return '\u{1F44D}';
    if (pct >= 0.5) return '\u{1F4AA}';
    return '\u{1F4DA}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _gradeColor.withValues(alpha: 0.1),
              _gradeColor.withValues(alpha: 0.02)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _gradeColor.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Text(_gradeEmoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(fit: StackFit.expand, children: [
              CircularProgressIndicator(
                value: pct,
                strokeWidth: 8,
                backgroundColor:
                    (dark ? DesignTokens.darkBorder : DesignTokens.border)
                        .withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation(_gradeColor),
              ),
              Center(
                child: Text(
                  '$score%',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _gradeColor),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Text(_gradeLabel,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _gradeColor)),
          const SizedBox(height: 4),
          Text('$correct of $total correct',
              style: TextStyle(
                  fontSize: 13,
                  color: dark
                      ? DesignTokens.darkTextSecondary
                      : DesignTokens.textSecondary)),
        ]),
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  final int correct;
  final int total;
  final String? timeDisplay;
  final bool dark;
  const _PerformanceRow(
      {required this.correct,
      required this.total,
      this.timeDisplay,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    final wrong = total - correct;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _StatChip(
            icon: Icons.check_circle,
            label: '$correct correct',
            color: DesignTokens.success,
            dark: dark),
        const SizedBox(width: 8),
        if (wrong > 0) ...[
          _StatChip(
              icon: Icons.cancel,
              label: '$wrong wrong',
              color: DesignTokens.error,
              dark: dark),
          const SizedBox(width: 8),
        ],
        if (timeDisplay != null)
          _StatChip(
              icon: Icons.timer_outlined,
              label: timeDisplay!,
              color: DesignTokens.info,
              dark: dark),
      ]),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool dark;
  const _StatChip(
      {required this.icon,
      required this.label,
      required this.color,
      required this.dark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }
}

class _AnswerReviewCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> answer;
  final bool dark;
  const _AnswerReviewCard(
      {required this.index, required this.answer, required this.dark});

  @override
  Widget build(BuildContext context) {
    final isCorrect = answer['isCorrect'] == true;
    final yourAnswer =
        (answer['selectedAnswer'] as Map?)?['answerText'] as String?;
    final correctAnswer =
        (answer['correctAnswer'] as Map?)?['answerText'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCorrect
              ? DesignTokens.success.withValues(alpha: 0.3)
              : DesignTokens.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isCorrect
                  ? DesignTokens.success.withValues(alpha: 0.1)
                  : DesignTokens.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(isCorrect ? Icons.check_circle : Icons.cancel,
                  size: 12,
                  color: isCorrect ? DesignTokens.success : DesignTokens.error),
              const SizedBox(width: 4),
              Text(isCorrect ? 'Correct' : 'Incorrect',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isCorrect
                          ? DesignTokens.success
                          : DesignTokens.error)),
            ]),
          ),
          const Spacer(),
          Text('Q${index + 1}',
              style: TextStyle(
                  fontSize: 11,
                  color: dark
                      ? DesignTokens.darkTextTertiary
                      : DesignTokens.textTertiary)),
        ]),
        if (!isCorrect && correctAnswer != null) ...[
          const SizedBox(height: 8),
          _LabeledText(
              label: 'Correct answer',
              text: correctAnswer,
              color: DesignTokens.success),
        ],
        if (yourAnswer != null) ...[
          const SizedBox(height: 4),
          _LabeledText(
              label: 'Your answer',
              text: yourAnswer,
              color:
                  isCorrect ? DesignTokens.textSecondary : DesignTokens.error),
        ],
      ]),
    );
  }
}

class _LabeledText extends StatelessWidget {
  final String label;
  final String text;
  final Color color;
  const _LabeledText(
      {required this.label, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ',
          style: TextStyle(
              fontSize: 11,
              color: DesignTokens.textTertiary,
              fontWeight: FontWeight.w500)),
      Expanded(
          child: Text(text,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color))),
    ]);
  }
}
