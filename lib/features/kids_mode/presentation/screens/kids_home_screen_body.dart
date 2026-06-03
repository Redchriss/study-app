import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import '../widgets/kid_auth_widgets.dart';
import '../widgets/kids_companion_character.dart';
import '../widgets/kids_home_app_bar.dart';
import '../widgets/kids_home_state_provider.dart';
import '../widgets/kids_home_screen_manager.dart';
import '../widgets/kids_lesson_view_section.dart';
import '../widgets/kids_offline_banner.dart';
import '../widgets/kids_session_overlay.dart';
import '../widgets/kids_subject_picker_section.dart';
import 'kids_home_screen_actions.dart';

class KidsHomeScreenBody extends ConsumerWidget {
  const KidsHomeScreenBody({
    super.key,
    required this.auth,
    required this.state,
    required this.actions,
    required this.mgr,
    required this.burstCtrl,
    required this.isOffline,
    required this.onBack,
  });

  final KidAuthState auth;
  final KidsHomeState state;
  final KidsHomeScreenActions actions;
  final KidsHomeScreenManager mgr;
  final AnimationController burstCtrl;
  final bool isOffline;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companionMood = state.showCorrectBurst
        ? CompanionMood.celebration
        : state.sessionWarningShown
            ? CompanionMood.encouraging
            : state.inQuiz
                ? CompanionMood.happy
                : CompanionMood.idle;
    return Theme(
      data: KidsVisualTheme.overlayOn(Theme.of(context)),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: KidsHomeAppBar(
            remainingSeconds:
                state.sessionActive ? state.sessionRemaining : null,
            durationSeconds: state.sessionActive ? state.sessionDuration : null,
          ),
          body: Stack(
            children: [
              SafeArea(
                child: Column(
                  children: [
                    KidsOfflineBanner(isOffline: isOffline),
                    if (state.sessionActive &&
                        state.sessionRemaining <= 300 &&
                        !actions.showWarningOverlay)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: KidsSoftStopBanner(
                          remainingSeconds: state.sessionRemaining,
                          sessionDuration: state.sessionDuration,
                          onExtend: actions.extendSession,
                        ),
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: DesignTokens.durNormal,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: state.selectedSubject == null
                            ? KidsSubjectPickerSection(
                                key: const ValueKey('picker'),
                                auth: auth,
                                state: state,
                                onStarsTap: () =>
                                    actions.onStarsTap(state.stars),
                                onClaimDailyChest: mgr.actions.claimDailyChest,
                                onSubjectSelected: actions.onSubjectPicked,
                              )
                            : KidsLessonViewSection(
                                key: const ValueKey('lesson'),
                                auth: auth,
                                state: state,
                                mgr: mgr,
                                burstCtrl: burstCtrl,
                                companionMood: companionMood,
                                onBack: onBack,
                                onTopicTap: actions.onTopicTap,
                                onReviewTap: () => mgr.actions
                                    .openRoadmapTopicById(state
                                        .roadmapSummary?['reviewTopicId']
                                        ?.toString()),
                                onNextTap: () => mgr.actions
                                    .openRoadmapTopicById(state
                                        .roadmapSummary?['nextTopicId']
                                        ?.toString()),
                                onJourneyTap: () =>
                                    mgr.actions.openJourney(auth),
                                onTapTopic: (tid) =>
                                    mgr.actions.openRoadmapTopicById(tid),
                                onTopicRoadmapTap: (tid) =>
                                    mgr.actions.openRoadmapTopicById(tid),
                                onChunkTap: actions.onChunkTap,
                                onListenTap: actions.onListenTap,
                                onStartQuiz: actions.onStartQuiz,
                                onNextLesson: actions.onNextLesson,
                                onQuizBack: actions.onQuizBack,
                                onQuizComplete: actions.onQuizComplete,
                                onRetryFetchLesson: actions.onRetryFetchLesson,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              if (actions.showWarningOverlay)
                KidsSessionWarningOverlay(
                  onContinue: actions.extendSession,
                  onStop: actions.onStopSession,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
