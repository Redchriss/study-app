import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import 'profile_hero.dart';
import 'profile_account_section.dart';
import 'profile_content_section.dart';
import 'profile_family_section.dart';
import 'profile_preferences_section.dart';
import 'profile_about_section.dart';
import 'profile_logout_button.dart';

class ProfileBody extends ConsumerWidget {
  const ProfileBody({super.key, required this.me, required this.refetch});

  final Map<String, dynamic>? me;
  final VoidCallback? refetch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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
                  const ProfileAccountSection()
                      .animate(delay: 60.ms)
                      .fadeIn()
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  const ProfileContentSection()
                      .animate(delay: 100.ms)
                      .fadeIn()
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  const ProfileFamilySection()
                      .animate(delay: 140.ms)
                      .fadeIn()
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  const ProfilePreferencesSection()
                      .animate(delay: 180.ms)
                      .fadeIn()
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 16),
                  const ProfileAboutSection().animate(delay: 200.ms).fadeIn(),
                  const SizedBox(height: 20),
                  const ProfileLogoutButton().animate(delay: 220.ms).fadeIn(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
