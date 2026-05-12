import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class QuizResultsScreen extends ConsumerWidget {
  final String attemptId;
  const QuizResultsScreen({super.key, required this.attemptId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Query(
      options: QueryOptions(document: gql(kQuizAttempt), variables: {'id': attemptId}),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final attempt = result.data?['quizAttempt'];
        if (attempt == null) return const Scaffold(body: Center(child: Text('Attempt not found')));
        final answers = (attempt['userAnswers'] as List?) ?? [];
        final correct = attempt['correctCount'] ?? answers.where((a) => a['isCorrect'] == true).length;
        final score = attempt['score']?.toStringAsFixed(0) ?? '0';
        final total = attempt['totalPoints'] ?? answers.length;
        return Scaffold(
          appBar: AppBar(title: Text(attempt['quiz']?['title'] ?? 'Results'), centerTitle: true),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            child: Column(children: [
              GlassCard(child: Column(children: [
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [DesignTokens.primary, DesignTokens.accent]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: Text('$score%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white))),
                ),
                const SizedBox(height: DesignTokens.spMd),
                Text('$correct/$total correct', style: theme.textTheme.titleMedium),
                Text('Time: ${attempt['timeDisplay'] ?? 'N/A'}', style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 13)),
              ])),
              const SizedBox(height: DesignTokens.spLg),
              ...answers.asMap().entries.map((e) {
                final a = e.value;
                final correct = a['isCorrect'] == true;
                final pts = a['pointsEarned'] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: DesignTokens.spSm),
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(color: correct ? DesignTokens.success.withValues(alpha: 0.3) : DesignTokens.error.withValues(alpha: 0.2)),
                    boxShadow: DesignTokens.shadowSm(dark),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(correct ? Icons.check_circle : Icons.cancel, color: correct ? DesignTokens.success : DesignTokens.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Question ${e.key + 1}', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600))),
                      Text('+$pts pts', style: TextStyle(fontSize: 12, color: correct ? DesignTokens.success : DesignTokens.textTertiary)),
                    ]),
                  ]),
                );
              }),
            ]),
          ),
        );
      },
    );
  }
}
