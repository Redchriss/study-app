import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_widgets.dart';
import 'kids_companion_character.dart';
import 'kids_daily_goal_ring.dart';
import 'kids_home_helpers.dart';
import 'kids_home_state_provider.dart';
import 'kids_hero_card.dart';
import 'kids_home_sections.dart';
import 'kids_subject_card.dart';

class KidsSubjectPickerSection extends StatelessWidget {
  const KidsSubjectPickerSection({
    super.key,
    required this.auth,
    required this.state,
    required this.onStarsTap,
    required this.onClaimDailyChest,
    required this.onSubjectSelected,
  });

  final KidAuthState auth;
  final KidsHomeState state;
  final VoidCallback onStarsTap;
  final VoidCallback onClaimDailyChest;
  final ValueChanged<Map<String, dynamic>> onSubjectSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KidsHeroCard(
            childName: auth.childName,
            standard: auth.standard,
            educationTrack: auth.educationTrack,
            summary: state.dailySummary,
            quizHotStreak: state.streak,
            stars: state.stars,
            onStarsTap: onStarsTap,
          ),
          if ((state.companionGreeting ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            KidsCompanionMessage(
              message: state.companionGreeting!.trim(),
              type: _companionType(state.rewardProfile),
            ),
          ],
          const SizedBox(height: 12),
          Semantics(
            label: kidsMascotMessage(state.dailySummary, auth),
            child: KidsMascotHint(
                message: kidsMascotMessage(state.dailySummary, auth)),
          ),
          const SizedBox(height: 12),
          if (state.dailySummary != null)
            Semantics(
              button: true,
              label: state.dailySummary!['chestAvailable'] == true
                  ? 'Daily chest available, claim it'
                  : 'Daily chest ${state.dailySummary!['chestClaimed'] == true ? 'claimed' : 'not available yet'}',
              child: Align(
                alignment: Alignment.centerLeft,
                child: KidsDailyChestChip(
                  available: state.dailySummary!['chestAvailable'] == true,
                  claimed: state.dailySummary!['chestClaimed'] == true,
                  onClaim: onClaimDailyChest,
                ),
              ),
            ),
          const SizedBox(height: 20),
          Semantics(
            header: true,
            child: Text(
              'Pick a path',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: KidsVisualTheme.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'One short lesson at a time',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: KidsVisualTheme.inkMuted.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 16),
          if (state.subjects.isEmpty)
            const KidsEmptySubjects()
          else
            ...state.subjects.map((s) {
              final name = s['name'] as String? ?? '';
              final c = kidsSubjectColor(name);
              final icon = kidsSubjectIcon(name);
              return Semantics(
                button: true,
                label: 'Subject: $name',
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: KidsSubjectCard(
                    name: name,
                    accent: c,
                    icon: icon,
                    onTap: () =>
                        onSubjectSelected(Map<String, dynamic>.from(s)),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  CompanionType _companionType(Map<String, dynamic>? rewardProfile) {
    final code = (rewardProfile?['equippedCompanion'] as String?) ?? 'sprout';
    // The animated catalog only ships sprout + flame skins today; energetic
    // companions map to flame, calmer ones to sprout.
    const flameLike = {'rocket', 'lion', 'flame'};
    return flameLike.contains(code) ? CompanionType.flame : CompanionType.sprout;
  }
}
