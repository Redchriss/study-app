import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'kids_companion_character.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../ai_tutor/presentation/providers/ai_tutor_state.dart';
import '../../kids_visual_theme.dart';
import 'kid_auth_widgets.dart';
import 'kids_home_state_provider.dart';
import 'kids_home_screen_manager.dart';
import 'kids_hero_card.dart';
import 'kids_home_sections.dart';
import 'kids_lesson_sidebar_cards.dart';
import 'kids_lesson_step_bar.dart';
import 'kids_topic_chip.dart';

class KidsLessonViewSection extends StatelessWidget {
  const KidsLessonViewSection({
    super.key,
    required this.auth,
    required this.state,
    required this.mgr,
    required this.burstCtrl,
    this.companionMood,
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
  final KidsHomeState state;
  final KidsHomeScreenManager mgr;
  final AnimationController burstCtrl;
  final CompanionMood? companionMood;
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
    if (state.loading) {
      return const LoadingWidget();
    }
    if (state.currentLesson == null && state.lessonItems.isEmpty) {
      return Semantics(
        label: 'No lesson available',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'No lesson available for this topic yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'Ask AI to generate a lesson',
                  child: FilledButton.icon(
                    onPressed: onRetryFetchLesson,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Ask AI to generate'),
                    style: FilledButton.styleFrom(
                        backgroundColor: KidsVisualTheme.pathBlue),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final subjectId = state.selectedSubject?['id']?.toString() ?? '';
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.sessionActive && state.sessionWarningShown)
                  Semantics(
                    liveRegion: true,
                    label: 'Session ending soon warning',
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: DesignTokens.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: DesignTokens.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Semantics(
                            excludeSemantics: true,
                            child: const Icon(Icons.timer_off_rounded,
                                color: DesignTokens.error, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Session ending soon! ${state.sessionRemaining ~/ 60}:${(state.sessionRemaining % 60).toString().padLeft(2, '0')} left',
                            style: const TextStyle(
                              color: DesignTokens.error,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Go back',
                      child: Material(
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
                    ),
                    const Spacer(),
                    Semantics(
                      label: 'Child name: ${auth.childName}',
                      child: Text(
                        auth.childName,
                        style: const TextStyle(
                            color: KidsVisualTheme.ink,
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (state.topics.isNotEmpty) ...[
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.topics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final topic = state.topics[index];
                        final selected =
                            topic['id'] == state.selectedTopic?['id'];
                        return Semantics(
                          button: true,
                          label:
                              'Topic: ${topic['name'] ?? ''}${selected ? ', selected' : ''}',
                          child: KidsTopicChip(
                            label: topic['name']?.toString() ?? 'Topic',
                            selected: selected,
                            onTap: () {
                              final topicId = topic['id']?.toString();
                              if (subjectId.isEmpty || topicId == null) return;
                              onTopicTap(topicId);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                KidsLessonSidebarCards(
                  subjectProgress: state.subjectProgress,
                  roadmapSummary: state.roadmapSummary,
                  rewardProfile: state.rewardProfile,
                  reviewQueue: state.reviewQueue,
                  topicRoadmap: state.topicRoadmap,
                  selectedTopicId: state.selectedTopic?['id']?.toString(),
                  onReviewTap: onReviewTap,
                  onNextTap: onNextTap,
                  onJourneyTap: onJourneyTap,
                  onTapTopic: onTapTopic,
                  onTopicRoadmapTap: onTopicRoadmapTap,
                ),
                KidsLessonStepBar(inQuiz: state.inQuiz),
                const SizedBox(height: 18),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (state.lessonItems.isNotEmpty)
                      Semantics(
                        label: 'Lesson content',
                        child: Column(
                          children: state.lessonItems.map((item) {
                            if (item is SurfaceItem) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Surface(
                                    surfaceContext: mgr.surfaceController
                                        .contextFor(item.surfaceId)),
                              );
                            }
                            if (item is TextItem) {
                              return Semantics(
                                liveRegion: true,
                                label: item.text,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(item.text,
                                        style: const TextStyle(
                                            fontSize: 15, height: 1.4)),
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }).toList(),
                        ),
                      ),
                    if (state.showCorrectBurst)
                      Semantics(
                        excludeSemantics: true,
                        child: CorrectBurstOverlay(controller: burstCtrl),
                      ),
                  ],
                ),
                if (!state.inQuiz && state.streak > 0) ...[
                  const SizedBox(height: 14),
                  KidsStreakChip(streak: state.streak, quizMode: true),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
