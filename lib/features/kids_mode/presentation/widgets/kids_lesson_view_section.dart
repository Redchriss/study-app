import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_screen_data.dart';
import 'kids_hero_card.dart';
import 'kids_home_sections.dart';
import 'kids_lesson_sidebar_cards.dart';
import 'kids_lesson_step_bar.dart';
import 'kids_topic_chip.dart';
import 'kids_multi_quiz_panel.dart';
import 'kids_visual_lesson.dart';

class KidsLessonViewSection extends StatelessWidget {
  const KidsLessonViewSection({
    super.key,
    required this.auth,
    required this.data,
    required this.onBack,
    required this.onTopicTap,
    required this.onReviewTap,
    required this.onNextTap,
    required this.onJourneyTap,
    required this.onTapTopic,
    required this.onTopicRoadmapTap,
    required this.onChunkTap,
    required this.onListenTap,
    required this.onStartQuiz,
    required this.onNextLesson,
    required this.onQuizBack,
    required this.onQuizComplete,
    required this.onRetryFetchLesson,
  });

  final KidAuthState auth;
  final KidsHomeScreenData data;
  final VoidCallback onBack;
  final ValueChanged<String> onTopicTap;
  final VoidCallback onReviewTap;
  final VoidCallback onNextTap;
  final VoidCallback onJourneyTap;
  final ValueChanged<String> onTapTopic;
  final ValueChanged<String> onTopicRoadmapTap;
  final ValueChanged<int> onChunkTap;
  final VoidCallback onListenTap;
  final VoidCallback onStartQuiz;
  final VoidCallback onNextLesson;
  final VoidCallback onQuizBack;
  final void Function({required int correct, required int total})
      onQuizComplete;
  final VoidCallback onRetryFetchLesson;

  @override
  Widget build(BuildContext context) {
    if (data.loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (data.currentLesson == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'No lesson available for this topic yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetryFetchLesson,
                icon: const Icon(Icons.refresh),
                label: const Text('Ask AI to generate'),
                style: FilledButton.styleFrom(
                    backgroundColor: KidsVisualTheme.pathBlue),
              ),
            ],
          ),
        ),
      );
    }
    final subjectId = data.selectedSubject?['id']?.toString() ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: onBack,
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded,
                              color: KidsVisualTheme.pathBlue, size: 22),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      auth.childName,
                      style: const TextStyle(
                          color: KidsVisualTheme.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (data.topics.isNotEmpty) ...[
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: data.topics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final topic = data.topics[index];
                        final selected =
                            topic['id'] == data.selectedTopic?['id'];
                        return KidsTopicChip(
                          label: topic['name']?.toString() ?? 'Topic',
                          selected: selected,
                          onTap: () {
                            final topicId = topic['id']?.toString();
                            if (subjectId.isEmpty || topicId == null) return;
                            onTopicTap(topicId);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                KidsLessonSidebarCards(
                  subjectProgress: data.subjectProgress,
                  roadmapSummary: data.roadmapSummary,
                  rewardProfile: data.rewardProfile,
                  reviewQueue: data.reviewQueue,
                  topicRoadmap: data.topicRoadmap,
                  selectedTopicId: data.selectedTopic?['id']?.toString(),
                  onReviewTap: onReviewTap,
                  onNextTap: onNextTap,
                  onJourneyTap: onJourneyTap,
                  onTapTopic: onTapTopic,
                  onTopicRoadmapTap: onTopicRoadmapTap,
                ),
                KidsLessonStepBar(inQuiz: data.inQuiz),
                const SizedBox(height: 18),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    KidsFloatingPanel(
                      child: AnimatedSwitcher(
                        duration: DesignTokens.durNormal,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: data.inQuiz
                            ? KidsMultiQuizPanel(
                                key: ValueKey(
                                    'quiz_${data.currentLesson?['id']}'),
                                lesson: data.currentLesson!,
                                onComplete: onQuizComplete,
                                onBack: onQuizBack,
                              )
                            : KidsVisualLessonPanel(
                                key: ValueKey(
                                    'lesson_${data.currentLesson?['id']}'),
                                lesson: data.currentLesson!,
                                isSpeaking: data.isSpeaking,
                                selectedChunk: data.selectedStoryChunk,
                                onChunkTap: onChunkTap,
                                onListenTap: onListenTap,
                                onStartQuiz: onStartQuiz,
                                onNextLesson: onNextLesson,
                              ),
                      ),
                    ),
                    if (data.showCorrectBurst)
                      CorrectBurstOverlay(controller: data.burstCtrl),
                  ],
                ),
                if (!data.inQuiz &&
                    (data.lessonState != null ||
                        data.quizReviewHint != null)) ...[
                  const SizedBox(height: 14),
                  KidsMasteryHint(
                    masteryLevel:
                        (data.lessonState?['masteryLevel'] as num?)?.toInt() ??
                            0,
                    reviewHint: data.quizReviewHint ??
                        data.lessonState?['nextReviewLabel']?.toString(),
                  ),
                ],
                if (!data.inQuiz && data.streak > 0) ...[
                  const SizedBox(height: 14),
                  KidsStreakChip(streak: data.streak, quizMode: true),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
