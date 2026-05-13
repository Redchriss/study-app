import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../main.dart';
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
                const SizedBox(height: DesignTokens.spMd),
                _MenuButton(icon: Icons.child_care_outlined, label: 'Kids mode', onTap: () => context.push('/kids')),
                _MenuButton(icon: Icons.edit, label: 'Edit Profile', onTap: () => context.go('/edit-profile')),
                _MenuButton(icon: Icons.emoji_events, label: 'Leaderboard', onTap: () => context.go('/leaderboard')),
                _MenuButton(icon: Icons.auto_awesome, label: 'Plans & Credits', onTap: () => context.go('/upgrade')),
                _MenuButton(icon: Icons.history, label: 'History', onTap: () => context.go('/history')),
                _MenuButton(icon: Icons.article, label: 'Past Papers', onTap: () => context.go('/past-papers')),
                _MenuButton(icon: Icons.library_books, label: 'Paper Library', onTap: () => context.go('/paper-library')),
                _MenuButton(icon: Icons.upload_file, label: 'Upload Material', onTap: () => context.go('/upload-material')),
                _MenuButton(icon: Icons.folder_special_outlined, label: 'My uploads', onTap: () => context.push('/my-uploads')),
                _MenuButton(icon: Icons.bookmark_outline, label: 'Bookmarks', onTap: () => context.go('/bookmarks')),
                _MenuButton(icon: Icons.info_outline, label: 'About Yaza', onTap: () => context.go('/about')),
                const Divider(height: DesignTokens.spMd),
                _MenuButton(
                  icon: ref.watch(themeModeProvider) == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  label: ref.watch(themeModeProvider) == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                  onTap: () {
                    final current = ref.read(themeModeProvider);
                    final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                    ref.read(themeModeProvider.notifier).state = next;
                    SharedPreferences.getInstance().then((p) => p.setString('theme_mode', next == ThemeMode.dark ? 'dark' : 'light'));
                  },
                ),
                const SizedBox(height: DesignTokens.spSm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Log out'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () { Navigator.pop(ctx); ref.read(authProvider.notifier).logout(); },
                            child: const Text('Log out'),
                          ),
                        ],
                      ),
                    ),
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

class _MenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18),
          label: Text(label),
        ),
      ),
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
          Text(label, style: const TextStyle(color: DesignTokens.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
