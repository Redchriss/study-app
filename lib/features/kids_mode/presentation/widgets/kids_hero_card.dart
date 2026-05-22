import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kids_daily_goal_ring.dart';

extension _KidsColorShades on Color {
  Color get shade700 => Color.alphaBlend(withValues(alpha: 0.85), Colors.black);
  Color get shade800 => Color.alphaBlend(withValues(alpha: 0.75), Colors.black);
}

class KidsStreakChip extends StatelessWidget {
  const KidsStreakChip({super.key, required this.streak, this.compact = false, this.quizMode = false});
  final int streak;
  final bool compact;
  final bool quizMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [DesignTokens.warning, DesignTokens.warning.withValues(alpha: 0.85)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: DesignTokens.warning.withValues(alpha: 0.35), offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, color: Colors.white.withValues(alpha: 0.95), size: compact ? 18 : 22),
          const SizedBox(width: 6),
          Text(
            quizMode ? '$streak quiz streak' : '$streak day streak',
            style: TextStyle(fontSize: compact ? 12 : 14, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.98)),
          ),
        ],
      ),
    );
  }
}

class KidsHeroCard extends StatelessWidget {
  const KidsHeroCard({
    super.key,
    required this.childName,
    required this.standard,
    required this.educationTrack,
    required this.summary,
    required this.quizHotStreak,
    required this.stars,
    required this.onStarsTap,
  });

  final String childName;
  final int standard;
  final String educationTrack;
  final Map<String, dynamic>? summary;
  final int quizHotStreak;
  final int stars;
  final VoidCallback onStarsTap;

  @override
  Widget build(BuildContext context) {
    final act = (summary?['activitiesToday'] as num?)?.toInt() ?? 0;
    final goal = (summary?['dailyGoal'] as num?)?.toInt() ?? 3;
    final cal = (summary?['calendarStreak'] as num?)?.toInt() ?? 0;
    final trackLabel = educationTrack == 'ecd' ? 'Early childhood' : 'Primary';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: KidsVisualTheme.pathBlue.withValues(alpha: 0.18), blurRadius: 0, offset: const Offset(0, 6)),
          ...DesignTokens.shadowSm(Theme.of(context).brightness == Brightness.dark),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hi, $childName!', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900, color: KidsVisualTheme.ink, letterSpacing: -0.5)),
                    const SizedBox(height: 6),
                    Text('$trackLabel \u00b7 Standard $standard', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: KidsVisualTheme.inkMuted)),
                  ],
                ),
              ),
              if (summary != null) ...[
                KidsDailyGoalRing(activities: act, goal: goal, size: 76, stroke: 8),
                const SizedBox(width: 12),
              ],
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Material(
                    color: KidsVisualTheme.sunGold.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onStarsTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(children: [
                          Icon(Icons.star_rounded, color: KidsVisualTheme.sunGold.shade700, size: 26),
                          const SizedBox(width: 4),
                          Text('$stars', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: KidsVisualTheme.sunGold.shade800)),
                        ]),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (cal > 0 || quizHotStreak > 0) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                if (cal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: KidsVisualTheme.pathBlue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.wb_sunny_rounded, color: KidsVisualTheme.pathBlue, size: 18),
                      const SizedBox(width: 6),
                      Text('$cal learning days in a row', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: KidsVisualTheme.ink)),
                    ]),
                  ),
                if (quizHotStreak > 0) KidsStreakChip(streak: quizHotStreak, compact: true, quizMode: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
