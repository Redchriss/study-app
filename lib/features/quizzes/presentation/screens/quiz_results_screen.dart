import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
          appBar: AppBar(
            title: Text(attempt['quiz']?['title'] ?? 'Results'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _showShareSheet(context, attempt, ref),
              ),
            ],
          ),
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

void _showShareSheet(BuildContext context, Map<String, dynamic>? attempt, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Share Quiz', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.groups),
              label: const Text('Share to a Circle'),
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/quizzes/${attempt?['quiz']?['slug']}/share');
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.public),
              label: const Text('Make Public'),
              onPressed: () async {
                final client = ref.read(graphqlClientProvider);
                await client.mutate(MutationOptions(
                  document: gql(kShareQuiz),
                  variables: {'quizSlug': attempt?['quiz']?['slug'], 'makePublic': true},
                ));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ),
        ]),
      ),
    ),
  );
}
