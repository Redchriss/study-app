import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Query(
      options: QueryOptions(document: gql(kMe)),
      builder: (result, {fetchMore, refetch}) {
        if (result.isLoading) {
          return Scaffold(
            appBar: AppBar(title: Text('Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final me = result.data?['me'];
        final profile = me?['profile'] as Map<String, dynamic>?;
        return Scaffold(
          appBar: AppBar(
            title: Text('Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            centerTitle: true,
            actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: () => refetch?.call())],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(DesignTokens.spMd),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                        child: Text(
                          (me?['username'] as String? ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: DesignTokens.primary),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spSm),
                      Text(me?['username'] ?? '', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      Text(me?['email'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spMd),
                GlassCard(
                  child: Column(
                    children: [
                      _ProfileRow(label: 'Education', value: profile?['educationLevel'] ?? 'Not set'),
                      const Divider(height: 1),
                      _ProfileRow(label: 'AI Credits', value: '${profile?['aiCredits'] ?? 0}'),
                      const Divider(height: 1),
                      _ProfileRow(label: 'Study Streak', value: '${profile?['studyStreak'] ?? 0} days'),
                      const Divider(height: 1),
                      _ProfileRow(label: 'Study Points', value: '${profile?['studyPoints'] ?? 0}'),
                      const Divider(height: 1),
                      _ProfileRow(label: 'Plan', value: profile?['activePlanName'] ?? 'Free'),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spXl),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Log Out'),
                    style: OutlinedButton.styleFrom(foregroundColor: DesignTokens.error),
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

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spSm, horizontal: DesignTokens.spMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: DesignTokens.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
