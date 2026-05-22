import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_widgets.dart';
import 'kids_daily_goal_ring.dart';
import 'kids_home_helpers.dart';
import 'kids_home_screen_data.dart';
import 'kids_home_sections.dart';
import 'kids_subject_card.dart';

class KidsSubjectPickerSection extends StatelessWidget {
  const KidsSubjectPickerSection({
    super.key,
    required this.auth,
    required this.data,
    required this.onStarsTap,
    required this.onClaimDailyChest,
    required this.onSubjectSelected,
  });

  final KidAuthState auth;
  final KidsHomeScreenData data;
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
            summary: data.dailySummary,
            quizHotStreak: data.streak,
            stars: data.stars,
            onStarsTap: onStarsTap,
          ),
          const SizedBox(height: 12),
          KidsMascotHint(message: kidsMascotMessage(data.dailySummary, auth)),
          const SizedBox(height: 12),
          if (data.dailySummary != null)
            Align(
              alignment: Alignment.centerLeft,
              child: KidsDailyChestChip(
                available: data.dailySummary!['chestAvailable'] == true,
                claimed: data.dailySummary!['chestClaimed'] == true,
                onClaim: onClaimDailyChest,
              ),
            ),
          const SizedBox(height: 20),
          Text(
            'Pick a path',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: KidsVisualTheme.ink,
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
          if (data.subjects.isEmpty)
            const KidsEmptySubjects()
          else
            ...data.subjects.map((s) {
              final name = s['name'] as String? ?? '';
              final c = kidsSubjectColor(name);
              final icon = kidsSubjectIcon(name);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: KidsSubjectCard(
                  name: name,
                  accent: c,
                  icon: icon,
                  onTap: () => onSubjectSelected(Map<String, dynamic>.from(s)),
                ),
              );
            }),
        ],
      ),
    );
  }
}
