import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/theme/app_colors.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Query(
      options: QueryOptions(document: gql(kMe)),
      builder: (result, {fetchMore, refetch}) {
        final me = result.data?['me'];
        final profile = me?['profile'] as Map<String, dynamic>?;
        if (result.isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        return Scaffold(
          appBar: AppBar(
            title: const Text('Profile'),
            centerTitle: true,
            actions: [
              IconButton(icon: const Icon(Icons.refresh), onPressed: () => refetch?.call()),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    (me?['username'] as String? ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(me?['username'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                Text(me?['email'] ?? '', style: TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                _StatRow(label: 'Education', value: profile?['educationLevel'] ?? 'Not set'),
                _StatRow(label: 'AI Credits', value: '${profile?['aiCredits'] ?? 0}'),
                _StatRow(label: 'Study Streak', value: '${profile?['studyStreak'] ?? 0} days'),
                _StatRow(label: 'Study Points', value: '${profile?['studyPoints'] ?? 0}'),
                _StatRow(label: 'Plan', value: profile?['activePlanName'] ?? 'Free'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const Icon(Icons.logout),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
