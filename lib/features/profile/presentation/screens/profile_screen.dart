import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/services/app_preferences_service.dart';
import '../../../../core/services/retention_service.dart';
import '../../../../main.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final preferences = AppPreferencesService();

    return Query(
      options: QueryOptions(document: gql(kMe)),
      builder: (result, {fetchMore, refetch}) {
        final me = result.data?['me'];

        if (result.isLoading && me == null) {
          return Scaffold(
            body: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              children: [
                const SizedBox(height: 120),
                const ShimmerBox(height: 160, radius: DesignTokens.radiusXl),
                const SizedBox(height: 16),
                const ShimmerBox(height: 200, radius: DesignTokens.radiusXl),
                const SizedBox(height: 16),
                const ShimmerBox(height: 280, radius: DesignTokens.radiusXl),
              ],
            ),
          );
        }

        if (result.hasException && me == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Profile', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              centerTitle: true,
            ),
            body: ErrorState(
              message: result.exception?.graphqlErrors.firstOrNull?.message ?? 'Could not load profile.',
              onRetry: () => refetch?.call(),
            ),
          );
        }

        final profile = me?['profile'] as Map<String, dynamic>?;
        final username = me?['username'] as String? ?? 'User';
        final email = me?['email'] as String? ?? '';
        final initials = username.trim().isNotEmpty ? username.trim()[0].toUpperCase() : 'U';
        final streak = profile?['studyStreak'] ?? 0;
        final points = profile?['studyPoints'] ?? 0;
        final credits = profile?['aiCredits'] ?? 0;
        final level = profile?['educationLevel'] as String? ?? 'secondary';
        final plan = profile?['activePlanName'] as String? ?? 'Free';
        final themeMode = ref.watch(themeModeProvider);

        return Scaffold(
          backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
          body: RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: CustomScrollView(
              slivers: [
                // ── Hero header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: _ProfileHero(
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

                      // ── Quick actions ────────────────────────────────────
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'MY ACCOUNT'),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(
                          children: [
                            _NavRow(icon: Icons.edit_outlined, label: 'Edit Profile', onTap: () => context.push('/edit-profile')),
                            _Divider(),
                            _NavRow(icon: Icons.auto_awesome_outlined, label: 'Plans & Credits', onTap: () => context.push('/upgrade')),
                            _Divider(),
                            _NavRow(icon: Icons.emoji_events_outlined, label: 'Leaderboard', onTap: () => context.push('/leaderboard')),
                            _Divider(),
                            _NavRow(icon: Icons.history_outlined, label: 'Study History', onTap: () => context.push('/history')),
                          ],
                        ),
                      ).animate(delay: 60.ms).fadeIn().slideY(begin: 0.04, end: 0),

                      // ── Content & papers ─────────────────────────────────
                      const SizedBox(height: 16),
                      _SectionLabel(label: 'STUDY CONTENT'),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(
                          children: [
                            _NavRow(icon: Icons.upload_file_outlined, label: 'Upload Material', onTap: () => context.push('/upload-material')),
                            _Divider(),
                            _NavRow(icon: Icons.folder_special_outlined, label: 'My Uploads', onTap: () => context.push('/my-uploads')),
                            _Divider(),
                            _NavRow(icon: Icons.article_outlined, label: 'Past Papers', onTap: () => context.push('/past-papers')),
                            _Divider(),
                            _NavRow(icon: Icons.library_books_outlined, label: 'Paper Library', onTap: () => context.push('/paper-library')),
                            _Divider(),
                            _NavRow(icon: Icons.bookmark_outline, label: 'Bookmarks', onTap: () => context.push('/bookmarks')),
                          ],
                        ),
                      ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.04, end: 0),

                      // ── Kids mode ────────────────────────────────────────
                      const SizedBox(height: 16),
                      _SectionLabel(label: 'FAMILY'),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(
                          children: [
                            _NavRow(
                              icon: Icons.child_care_outlined,
                              label: 'Kids Mode',
                              badge: 'Safe',
                              badgeColor: DesignTokens.success,
                              onTap: () => context.push('/kids'),
                            ),
                            _Divider(),
                            _NavRow(icon: Icons.family_restroom_outlined, label: 'Kids Progress', onTap: () => context.push('/kids/progress')),
                          ],
                        ),
                      ).animate(delay: 140.ms).fadeIn().slideY(begin: 0.04, end: 0),

                      // ── Preferences ──────────────────────────────────────
                      const SizedBox(height: 16),
                      _SectionLabel(label: 'PREFERENCES'),
                      const SizedBox(height: 10),
                      GlassCard(
                        child: Column(
                          children: [
                            // Theme toggle
                            ListTile(
                              leading: Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: (themeMode == ThemeMode.dark ? DesignTokens.warning : DesignTokens.primary).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                ),
                                child: Icon(
                                  themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                                  size: 18,
                                  color: themeMode == ThemeMode.dark ? DesignTokens.warning : DesignTokens.primary,
                                ),
                              ),
                              title: Text(
                                themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              trailing: const Icon(Icons.chevron_right, size: 18, color: DesignTokens.textTertiary),
                              onTap: () {
                                final current = ref.read(themeModeProvider);
                                final next = current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
                                ref.read(themeModeProvider.notifier).state = next;
                                SharedPreferences.getInstance().then(
                                  (p) => p.setString('theme_mode', next == ThemeMode.dark ? 'dark' : 'light'),
                                );
                              },
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                            _Divider(),
                            // Low data mode
                            _AsyncPreferenceSwitch(
                              icon: Icons.data_saver_on_outlined,
                              iconColor: DesignTokens.accent,
                              loadValue: preferences.isLowDataMode,
                              onChanged: (value) async {
                                await preferences.setLowDataMode(value);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(value ? 'Low-data mode enabled.' : 'Low-data mode disabled.')),
                                  );
                                }
                              },
                              title: 'Low-data Mode',
                              subtitle: 'Reduces heavy previews on slow networks.',
                            ),
                            _Divider(),
                            // Study reminders
                            _AsyncPreferenceSwitch(
                              icon: Icons.notifications_outlined,
                              iconColor: DesignTokens.secondary,
                              loadValue: preferences.studyRemindersEnabled,
                              onChanged: (value) async {
                                await preferences.setStudyRemindersEnabled(value);
                                await RetentionService().refreshStudyReminder();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(value ? 'Study reminders on.' : 'Study reminders off.')),
                                  );
                                }
                              },
                              title: 'Study Reminders',
                              subtitle: 'Daily nudge to keep your streak alive.',
                            ),
                          ],
                        ),
                      ).animate(delay: 180.ms).fadeIn().slideY(begin: 0.04, end: 0),

                       // ── Legal & About ────────────────────────────────────
                       const SizedBox(height: 16),
                       GlassCard(
                         child: Column(
                           children: [
                             _NavRow(icon: Icons.info_outline, label: 'About Yaza', onTap: () => context.push('/about')),
                             _Divider(),
                             _NavRow(icon: Icons.gavel_outlined, label: 'Terms of Service', onTap: () => context.push('/legal/terms')),
                             _Divider(),
                             _NavRow(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/legal/privacy')),
                             _Divider(),
                             _NavRow(icon: Icons.help_outline_rounded, label: 'FAQ', onTap: () => context.push('/legal/faq')),
                             _Divider(),
                             _NavRow(icon: Icons.support_agent_outlined, label: 'Support & Contact', onTap: () => context.push('/legal/support')),
                           ],
                         ),
                       ).animate(delay: 200.ms).fadeIn(),


                      // ── Sign out ─────────────────────────────────────────
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                              ),
                              title: const Text('Log out?', style: TextStyle(fontWeight: FontWeight.w800)),
                              content: const Text('You will need to log in again to access your study data.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref.read(authProvider.notifier).logout();
                                  },
                                  child: const Text('Log out', style: TextStyle(color: DesignTokens.error)),
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
                              borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                            ),
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
      },
    );
  }
}

// ─── Hero header ──────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final String initials, username, email, level, plan;
  final dynamic streak, points, credits;
  final bool dark;

  const _ProfileHero({
    required this.initials,
    required this.username,
    required this.email,
    required this.level,
    required this.plan,
    required this.streak,
    required this.points,
    required this.credits,
    required this.dark,
  });

  static const _levelColors = {
    'primary': Color(0xFF27AE60),
    'secondary': Color(0xFF1B6CA8),
    'tertiary': Color(0xFF7A4D9E),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final levelColor = _levelColors[level] ?? DesignTokens.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            levelColor.withValues(alpha: 0.85),
            levelColor.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXxl),
        boxShadow: DesignTokens.shadowMd(dark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _HeroBadge(label: _levelLabel(level)),
                        const SizedBox(width: 6),
                        _HeroBadge(label: plan, icon: Icons.star_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _StatPill(icon: Icons.local_fire_department, value: '$streak', label: 'Streak', color: Colors.orange),
              const SizedBox(width: 8),
              _StatPill(icon: Icons.stars_rounded, value: '$points', label: 'Points', color: Colors.amber),
              const SizedBox(width: 8),
              _StatPill(icon: Icons.bolt_rounded, value: '$credits', label: 'Credits', color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  static String _levelLabel(String level) {
    switch (level) {
      case 'primary': return 'Primary';
      case 'tertiary': return 'Tertiary';
      default: return 'Secondary';
    }
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _HeroBadge({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.amber),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatPill({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: DesignTokens.textTertiary,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Nav row inside card ──────────────────────────────────────────────────────
class _NavRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _NavRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
              child: Icon(icon, size: 16, color: DesignTokens.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (badgeColor ?? DesignTokens.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeColor ?? DesignTokens.primary,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right, size: 16, color: DesignTokens.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 58, endIndent: 0);
  }
}

// ─── Preference toggle ────────────────────────────────────────────────────────
class _AsyncPreferenceSwitch extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final Future<bool> Function() loadValue;
  final Future<void> Function(bool) onChanged;
  final String title, subtitle;

  const _AsyncPreferenceSwitch({
    required this.icon,
    required this.iconColor,
    required this.loadValue,
    required this.onChanged,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AsyncPreferenceSwitch> createState() => _AsyncPreferenceSwitchState();
}

class _AsyncPreferenceSwitchState extends State<_AsyncPreferenceSwitch> {
  bool? _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    widget.loadValue().then((v) {
      if (mounted) setState(() => _value = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
            ),
            child: Icon(widget.icon, size: 16, color: widget.iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(
                  widget.subtitle,
                  style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          _value == null
              ? const SizedBox(width: 36, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Switch.adaptive(
                  value: _value!,
                  onChanged: _saving
                      ? null
                      : (v) async {
                          setState(() { _value = v; _saving = true; });
                          await widget.onChanged(v);
                          if (mounted) setState(() => _saving = false);
                        },
                  activeColor: DesignTokens.primary,
                ),
        ],
      ),
    );
  }
}
