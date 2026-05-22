import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';
import 'kids_home_sections.dart';
import 'kids_mission_board.dart';
import 'kids_playful_button.dart';
import 'kids_progress_snapshot_card.dart';
import 'kids_topic_roadmap_card.dart';

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
        if (subjectProgress != null) ...[
          KidsProgressSnapshotCard(
            lessonsCompleted:
                (subjectProgress!['lessonsCompleted'] as num?)?.toInt() ?? 0,
            quizzesTaken:
                (subjectProgress!['quizzesTaken'] as num?)?.toInt() ?? 0,
            quizzesCorrect:
                (subjectProgress!['quizzesCorrect'] as num?)?.toInt() ?? 0,
            starsEarned:
                (subjectProgress!['starsEarned'] as num?)?.toInt() ?? 0,
          ),
          const SizedBox(height: 14),
        ],
        if (roadmapSummary != null) ...[
          KidsMissionBoard(
            readyReviewCount:
                (roadmapSummary!['readyReviewCount'] as num?)?.toInt() ?? 0,
            masteredCount:
                (roadmapSummary!['masteredCount'] as num?)?.toInt() ?? 0,
            inProgressCount:
                (roadmapSummary!['inProgressCount'] as num?)?.toInt() ?? 0,
            untouchedCount:
                (roadmapSummary!['untouchedCount'] as num?)?.toInt() ?? 0,
            onReviewTap: onReviewTap,
            onNextTap: onNextTap,
          ),
          const SizedBox(height: 14),
        ],
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
                            color: KidsVisualTheme.ink),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(rewardProfile!['xp'] as num?)?.toInt() ?? 0} xp · ${(rewardProfile!['coins'] as num?)?.toInt() ?? 0} coins',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: KidsVisualTheme.inkMuted),
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
        if (reviewQueue.isNotEmpty) ...[
          KidsReviewQueue(reviewQueue: reviewQueue, onTapTopic: onTapTopic),
          const SizedBox(height: 14),
        ],
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
                  statusLabel:
                      state?['statusLabel']?.toString() ?? 'Start here',
                  masteryLevel: (state?['masteryLevel'] as num?)?.toInt() ?? 0,
                  selected: topicId == (selectedTopicId ?? ''),
                  readyForReview: state?['readyForReview'] == true,
                  isMastered: state?['isMastered'] == true,
                  nextReviewLabel: state?['nextReviewLabel']?.toString(),
                  onTap: topicId.isEmpty
                      ? () {}
                      : () => onTopicRoadmapTap(topicId),
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
