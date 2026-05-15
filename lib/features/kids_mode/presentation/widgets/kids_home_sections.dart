import 'package:flutter/material.dart';

import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kids_daily_goal_ring.dart';
import 'kids_mission_board.dart';
import 'kids_playful_button.dart';
import 'kids_progress_snapshot_card.dart';
import 'kids_topic_roadmap_card.dart';

class KidsReviewQueue extends StatelessWidget {
  const KidsReviewQueue({
    super.key,
    required this.reviewQueue,
    required this.onTapTopic,
  });

  final List<Map<String, dynamic>> reviewQueue;
  final ValueChanged<String> onTapTopic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5E8),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to review',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: KidsVisualTheme.ink,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: reviewQueue.map((item) {
              final topicId = item['topicId']?.toString() ?? '';
              final state = item['state'] is Map ? Map<String, dynamic>.from(item['state'] as Map) : null;
              return ActionChip(
                avatar: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFFF39C12)),
                label: Text(item['topicName']?.toString() ?? 'Topic'),
                onPressed: topicId.isEmpty ? null : () => onTapTopic(topicId),
                tooltip: state?['nextReviewLabel']?.toString(),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class KidsMasteryHint extends StatelessWidget {
  const KidsMasteryHint({
    super.key,
    required this.masteryLevel,
    this.reviewHint,
  });

  final int masteryLevel;
  final String? reviewHint;

  @override
  Widget build(BuildContext context) {
    final message = masteryLevel >= 4
        ? 'Amazing work. This topic is nearly mastered.'
        : masteryLevel >= 2
            ? 'Nice progress. One more strong quiz will build mastery.'
            : 'Keep practicing. Short repeat sessions help memory stick.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_alt_rounded, color: KidsVisualTheme.pathBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reviewHint == null || reviewHint!.trim().isEmpty
                  ? message
                  : '$message ${reviewHint!.trim()}.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: KidsVisualTheme.ink,
                height: 1.35,
              ),
            ),
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
                    Text(
                      'Hi, $childName!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: KidsVisualTheme.ink,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$trackLabel · Standard $standard',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KidsVisualTheme.inkMuted,
                      ),
                    ),
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
                        child: Row(
                          children: [
                            Icon(Icons.star_rounded, color: KidsVisualTheme.sunGold.shade700, size: 26),
                            const SizedBox(width: 4),
                            Text(
                              '$stars',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: KidsVisualTheme.sunGold.shade800,
                              ),
                            ),
                          ],
                        ),
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
              spacing: 8,
              runSpacing: 8,
              children: [
                if (cal > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: KidsVisualTheme.pathBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wb_sunny_rounded, color: KidsVisualTheme.pathBlue, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          '$cal learning days in a row',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: KidsVisualTheme.ink),
                        ),
                      ],
                    ),
                  ),
                if (quizHotStreak > 0)
                  KidsStreakChip(streak: quizHotStreak, compact: true, quizMode: true),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

extension _KidsColorShades on Color {
  Color get shade700 => Color.alphaBlend(withValues(alpha: 0.85), Colors.black);
  Color get shade800 => Color.alphaBlend(withValues(alpha: 0.75), Colors.black);
}

class KidsStreakChip extends StatelessWidget {
  const KidsStreakChip({
    super.key,
    required this.streak,
    this.compact = false,
    this.quizMode = false,
  });

  final int streak;
  final bool compact;
  final bool quizMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.warning, DesignTokens.warning.withValues(alpha: 0.85)],
        ),
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
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.98),
            ),
          ),
        ],
      ),
    );
  }
}

class KidsEmptySubjects extends StatelessWidget {
  const KidsEmptySubjects({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: KidsVisualTheme.inkMuted),
          SizedBox(height: 12),
          Text(
            'Subjects could not load. Check your connection and pull to refresh from the parent app.',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w600, color: KidsVisualTheme.inkMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class KidsFloatingPanel extends StatelessWidget {
  const KidsFloatingPanel({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: KidsVisualTheme.pathBlue.withValues(alpha: 0.12), offset: const Offset(0, 8), blurRadius: 24),
        ],
      ),
      child: child,
    );
  }
}

class CorrectBurstOverlay extends StatelessWidget {
  const CorrectBurstOverlay({
    super.key,
    required this.controller,
  });

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: -8,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final t = Curves.easeOut.transform(controller.value);
            return Opacity(
              opacity: 1.0 - t,
              child: Transform.scale(
                scale: 0.85 + 0.35 * t,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final rot = (i - 2) * 0.15 * (1 - t);
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Transform.rotate(
                        angle: rot,
                        child: Icon(Icons.star_rounded, size: 32 + 12 * t, color: KidsVisualTheme.sunGold),
                      ),
                    );
                  }),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─── Lesson sidebar cards ──────────────────────────────────────────────────────
/// Groups all the sidebar cards shown above the lesson/quiz panel.
/// Extracted from _buildLesson to keep kids_home_screen.dart manageable.
class KidsLessonSidebarCards extends StatelessWidget {
  const KidsLessonSidebarCards({
    super.key,
    required this.subjectProgress,
    required this.roadmapSummary,
    required this.rewardProfile,
    required this.reviewQueue,
    required this.topicRoadmap,
    required this.selectedTopicId,
    required this.onReviewTap,
    required this.onNextTap,
    required this.onJourneyTap,
    required this.onTapTopic,
    required this.onTopicRoadmapTap,
  });

  final Map<String, dynamic>? subjectProgress;
  final Map<String, dynamic>? roadmapSummary;
  final Map<String, dynamic>? rewardProfile;
  final List<Map<String, dynamic>> reviewQueue;
  final List<Map<String, dynamic>> topicRoadmap;
  final String? selectedTopicId;
  final VoidCallback onReviewTap;
  final VoidCallback onNextTap;
  final VoidCallback onJourneyTap;
  final ValueChanged<String> onTapTopic;
  final ValueChanged<String> onTopicRoadmapTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress snapshot
        if (subjectProgress != null) ...[
          KidsProgressSnapshotCard(
            lessonsCompleted: (subjectProgress!['lessonsCompleted'] as num?)?.toInt() ?? 0,
            quizzesTaken: (subjectProgress!['quizzesTaken'] as num?)?.toInt() ?? 0,
            quizzesCorrect: (subjectProgress!['quizzesCorrect'] as num?)?.toInt() ?? 0,
            starsEarned: (subjectProgress!['starsEarned'] as num?)?.toInt() ?? 0,
          ),
          const SizedBox(height: 14),
        ],

        // Mission board
        if (roadmapSummary != null) ...[
          KidsMissionBoard(
            readyReviewCount: (roadmapSummary!['readyReviewCount'] as num?)?.toInt() ?? 0,
            masteredCount: (roadmapSummary!['masteredCount'] as num?)?.toInt() ?? 0,
            inProgressCount: (roadmapSummary!['inProgressCount'] as num?)?.toInt() ?? 0,
            untouchedCount: (roadmapSummary!['untouchedCount'] as num?)?.toInt() ?? 0,
            onReviewTap: onReviewTap,
            onNextTap: onNextTap,
          ),
          const SizedBox(height: 14),
        ],

        // Reward / journey card
        if (rewardProfile != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${(rewardProfile!['level'] as num?)?.toInt() ?? 1} journey',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: KidsVisualTheme.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(rewardProfile!['xp'] as num?)?.toInt() ?? 0} xp · '
                        '${(rewardProfile!['coins'] as num?)?.toInt() ?? 0} coins',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: KidsVisualTheme.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                KidsPlayfulSecondaryButton(
                  icon: Icons.map_rounded,
                  label: 'Journey',
                  color: KidsVisualTheme.pathBlue,
                  onTap: onJourneyTap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Review queue
        if (reviewQueue.isNotEmpty) ...[
          KidsReviewQueue(reviewQueue: reviewQueue, onTapTopic: onTapTopic),
          const SizedBox(height: 14),
        ],

        // Topic roadmap strip
        if (topicRoadmap.isNotEmpty) ...[
          SizedBox(
            height: 138,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: topicRoadmap.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = topicRoadmap[index];
                final state = item['state'] is Map
                    ? Map<String, dynamic>.from(item['state'] as Map)
                    : null;
                final topicId = item['topicId']?.toString() ?? '';
                return KidsTopicRoadmapCard(
                  title: item['topicName']?.toString() ?? 'Topic',
                  statusLabel: state?['statusLabel']?.toString() ?? 'Start here',
                  masteryLevel: (state?['masteryLevel'] as num?)?.toInt() ?? 0,
                  selected: topicId == (selectedTopicId ?? ''),
                  readyForReview: state?['readyForReview'] == true,
                  isMastered: state?['isMastered'] == true,
                  nextReviewLabel: state?['nextReviewLabel']?.toString(),
                  onTap: topicId.isEmpty ? () {} : () => onTopicRoadmapTap(topicId),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}
