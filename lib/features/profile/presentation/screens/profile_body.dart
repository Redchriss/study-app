import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/retention_service.dart';
import '../../../../main.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'profile_hero.dart';
import 'profile_list_widgets.dart';
import 'profile_preference_switch.dart';

class ProfileBody extends ConsumerWidget {
  const ProfileBody({super.key, required this.me, required this.refetch});

  final Map<String, dynamic>? me;
  final VoidCallback? refetch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final preferences = AppPreferencesService();
    final profile = me?['profile'] as Map<String, dynamic>?;
    final username = me?['username'] as String? ?? 'User';
    final email = me?['email'] as String? ?? '';
    final initials =
        username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : 'U';
    final streak = profile?['studyStreak'] ?? 0;
    final points = profile?['studyPoints'] ?? 0;
    final credits = profile?['aiCredits'] ?? 0;
    final level = profile?['educationLevel'] as String? ?? 'secondary';
    final plan = profile?['activePlanName'] as String? ?? 'Free';
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor:
          dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: RefreshIndicator(
        onRefresh: () async => refetch?.call(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ProfileHero(
                initials: initials,
                username: username,
                email: email,
                level: level,
                plan: plan,
                streak: streak,
                points: points,
                credits: credits,
                dark: dark,
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04, end: 0),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 20),
                  const SectionLabel(label: 'MY ACCOUNT'),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        NavRow(
                            icon: Icons.edit_outlined,
                            label: 'Edit Profile',
                            onTap: () => context.push('/edit-profile')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.auto_awesome_outlined,
                            label: 'Plans & Credits',
                            onTap: () => context.push('/upgrade')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.emoji_events_outlined,
                            label: 'Leaderboard',
                            onTap: () => context.push('/leaderboard')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.history_outlined,
                            label: 'Study History',
                            onTap: () => context.push('/history')),
                      ],
                    ),
                  ).animate(delay: 60.ms).fadeIn().slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  const SectionLabel(label: 'STUDY CONTENT'),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        NavRow(
                            icon: Icons.upload_file_outlined,
                            label: 'Upload Material',
                            onTap: () => context.push('/upload-material')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.folder_special_outlined,
                            label: 'My Uploads',
                            onTap: () => context.push('/my-uploads')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.article_outlined,
                            label: 'Past Papers',
                            onTap: () => context.push('/past-papers')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.library_books_outlined,
                            label: 'Paper Library',
                            onTap: () => context.push('/paper-library')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.bookmark_outline,
                            label: 'Bookmarks',
                            onTap: () => context.push('/bookmarks')),
                      ],
                    ),
                  ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  const SectionLabel(label: 'FAMILY'),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        NavRow(
                            icon: Icons.child_care_outlined,
                            label: 'Kids Mode',
                            badge: 'Safe',
                            badgeColor: DesignTokens.success,
                            onTap: () => context.push('/kids')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.family_restroom_outlined,
                            label: 'Kids Progress',
                            onTap: () => context.push('/kids/progress')),
                      ],
                    ),
                  ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  const SectionLabel(label: 'PREFERENCES'),
                  const SizedBox(height: 10),
                  GlassCard(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (themeMode == ThemeMode.dark
                                      ? DesignTokens.warning
                                      : DesignTokens.primary)
                                  .withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusMd),
                            ),
                            child: Icon(
                              themeMode == ThemeMode.dark
                                  ? Icons.light_mode_outlined
                                  : Icons.dark_mode_outlined,
                              size: 18,
                              color: themeMode == ThemeMode.dark
                                  ? DesignTokens.warning
                                  : DesignTokens.primary,
                            ),
                          ),
                          title: Text(
                              themeMode == ThemeMode.dark
                                  ? 'Light Mode'
                                  : 'Dark Mode',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          trailing: const Icon(Icons.chevron_right,
                              size: 18, color: DesignTokens.textTertiary),
                          onTap: () {
                            final current = ref.read(themeModeProvider);
                            final next = current == ThemeMode.dark
                                ? ThemeMode.light
                                : ThemeMode.dark;
                            ref.read(themeModeProvider.notifier).state = next;
                            SharedPreferences.getInstance().then((p) =>
                                p.setString('theme_mode',
                                    next == ThemeMode.dark ? 'dark' : 'light'));
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                        const SectionDivider(),
                        AsyncPreferenceSwitch(
                          icon: Icons.data_saver_on_outlined,
                          iconColor: DesignTokens.accent,
                          loadValue: preferences.isLowDataMode,
                          onChanged: (value) async {
                            await preferences.setLowDataMode(value);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(value
                                        ? 'Low-data mode enabled.'
                                        : 'Low-data mode disabled.')),
                              );
                            }
                          },
                          title: 'Low-data Mode',
                          subtitle: 'Reduces heavy previews on slow networks.',
                        ),
                        const SectionDivider(),
                        AsyncPreferenceSwitch(
                          icon: Icons.notifications_outlined,
                          iconColor: DesignTokens.secondary,
                          loadValue: preferences.studyRemindersEnabled,
                          onChanged: (value) async {
                            await preferences.setStudyRemindersEnabled(value);
                            await RetentionService().refreshStudyReminder();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(value
                                        ? 'Study reminders on.'
                                        : 'Study reminders off.')),
                              );
                            }
                          },
                          title: 'Study Reminders',
                          subtitle: 'Daily nudge to keep your streak alive.',
                        ),
                      ],
                    ),
                  ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      children: [
                        NavRow(
                            icon: Icons.info_outline,
                            label: 'About Yaza',
                            onTap: () => context.push('/about')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.gavel_outlined,
                            label: 'Terms of Service',
                            onTap: () => context.push('/legal/terms')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.privacy_tip_outlined,
                            label: 'Privacy Policy',
                            onTap: () => context.push('/legal/privacy')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.help_outline_rounded,
                            label: 'FAQ',
                            onTap: () => context.push('/legal/faq')),
                        const SectionDivider(),
                        NavRow(
                            icon: Icons.support_agent_outlined,
                            label: 'Support & Contact',
                            onTap: () => context.push('/legal/support')),
                      ],
                    ),
                  ).animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(DesignTokens.radiusXl)),
                          title: const Text('Log out?',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          content: const Text(
                              'You will need to log in again to access your study data.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(authProvider.notifier).logout();
                              },
                              child: const Text('Log out',
                                  style: TextStyle(color: DesignTokens.error)),
                            ),
                          ],
                        ),
                      ),
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DesignTokens.error,
                        side: const BorderSide(color: DesignTokens.error),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(DesignTokens.radiusLg)),
                      ),
                    ),
                  ).animate(delay: 220.ms).fadeIn(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
