import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/config/theme/app_colors.dart';

const kLeaderboard = r'''
query Leaderboard {
  me { username profile { studyPoints studyStreak } }
}
''';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leaderboard'), centerTitle: true),
      body: Query(
        options: QueryOptions(document: gql(kLeaderboard)),
        builder: (result, {refetch}) {
          if (result.isLoading) return const Center(child: CircularProgressIndicator());
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events_outlined, size: 80, color: AppColors.secondary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('Leaderboard coming soon', style: TextStyle(color: AppColors.textSecondary, fontSize: 18)),
                const SizedBox(height: 8),
                Text('Your points: ${result.data?['me']?['profile']?['studyPoints'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          );
        },
      ),
    );
  }
}
