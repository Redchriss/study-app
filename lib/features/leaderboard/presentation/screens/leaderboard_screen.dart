import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
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
        options: QueryOptions(document: gql(r'query L { me { username profile { studyPoints studyStreak } } }')),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          final pts = result.data?['me']?['profile']?['studyPoints'] ?? 0;
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                ]),
              ),
            ]),
          );
        },
      ),
    );
  }
}
