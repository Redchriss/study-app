import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Leaderboard', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), centerTitle: true),
      body: Query(
        options: QueryOptions(document: gql(kLeaderboard)),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          final me = result.data?['me'];
          final pts = me?['profile']?['studyPoints'] ?? 0;
          final streak = me?['profile']?['studyStreak'] ?? 0;
          return ListView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            children: [
              GlassCard(
                child: Column(children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: DesignTokens.warning.withValues(alpha: 0.15), shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events, size: 40, color: DesignTokens.warning),
                  ),
                  const SizedBox(height: DesignTokens.spMd),
                  Text('$pts', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: DesignTokens.warning)),
                  const Text('points earned', style: TextStyle(color: DesignTokens.textSecondary)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.local_fire_department, size: 18, color: DesignTokens.warning),
                    const SizedBox(width: 4),
                    Text('$streak day streak', style: const TextStyle(color: DesignTokens.textSecondary)),
                  ]),
                ]),
              ),
              const SizedBox(height: DesignTokens.spLg),
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spMd),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('How to earn points', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: DesignTokens.spSm),
                    _TipRow(icon: Icons.quiz, text: 'Complete quizzes'),
                    _TipRow(icon: Icons.auto_awesome, text: 'Use AI study tools'),
                    _TipRow(icon: Icons.local_fire_department, text: 'Maintain your study streak'),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  final IconData icon; final String text;
  const _TipRow({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Icon(icon, size: 16, color: DesignTokens.primary),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: DesignTokens.textSecondary)),
      ]),
    );
  }
}
