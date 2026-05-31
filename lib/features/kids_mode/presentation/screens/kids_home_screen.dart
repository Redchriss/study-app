import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import '../widgets/kid_auth_widgets.dart';
import '../widgets/kids_home_app_bar.dart';
import '../widgets/kids_home_screen_manager.dart';
import '../widgets/kids_home_state_provider.dart';
import '../widgets/kids_lesson_view_section.dart';
import '../widgets/kids_subject_picker_section.dart';
import 'kids_home_builders.dart';

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});
  @override
  ConsumerState<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen>
    with SingleTickerProviderStateMixin {
  late final KidsHomeScreenManager _mgr;
  final _tts = FlutterTts();
  bool _redirectScheduled = false;
  late final AnimationController _burstCtrl;
  Timer? _sessionTimer;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _mgr = KidsHomeScreenManager(ref);
    _mgr.attach(
      getContext: () => context,
      isMounted: () => mounted,
    );
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) {
        ref
            .read(kidsHomeStateProvider.notifier)
            .apply((s) => s.copyWith(isSpeaking: false));
      }
    });
    final auth = ref.read(kidAuthStateProvider);
    if (auth.isAuthenticated && auth.token != null) {
      ref.read(kidsHomeStateProvider.notifier).setChildId(auth.token ?? '');
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _burstCtrl.dispose();
    _tts.stop();
    _tts.setCompletionHandler(() {});
    super.dispose();
  }

  void _startSessionTimer() {
    _sessionTimer?.cancel();
    final auth = ref.read(kidAuthStateProvider);
    final duration = auth.standard <= 2 ? 1200 : 1800;
    ref.read(kidsHomeStateProvider.notifier).startSession(duration);
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _sessionTimer?.cancel();
        return;
      }
      ref.read(kidsHomeStateProvider.notifier).tickSession();
    });
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    ref.read(kidsHomeStateProvider.notifier).endSession();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    if (!mounted) return;
    ref
        .read(kidsHomeStateProvider.notifier)
        .apply((s) => s.copyWith(isSpeaking: true));
    try {
      await _tts.speak(
          text.replaceAll('\n', ' ').replaceAll(RegExp(r'\{[^}]*\}'), ''));
    } catch (_) {
      if (mounted) {
        ref
            .read(kidsHomeStateProvider.notifier)
            .apply((s) => s.copyWith(isSpeaking: false));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Reading aloud is not available on this device'),
              backgroundColor: DesignTokens.error),
        );
      }
    }
  }

  void _onSubjectPicked(Map<String, dynamic> subject) {
    final sid = subject['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    final auth = ref.read(kidAuthStateProvider);
    ref.read(kidsHomeStateProvider.notifier).apply((s) => s.copyWith(
          selectedSubject: Map<String, dynamic>.from(subject),
          selectedTopic: null,
          topics: [],
          subjectProgress: null,
        ));
    _mgr.fetchTopics(sid, auth.standard);
    _mgr.fetchSubjectProgress(sid, auth.standard);
    _mgr.fetchRoadmap(sid, auth.standard);
    final subjectName = subject['name']?.toString() ?? 'this subject';
    _mgr.startGenUiLesson(subjectName);
    _startSessionTimer();
  }

  void _onStarsTap() {
    HapticFeedback.selectionClick();
    _speak(
        'You have ${ref.read(kidsHomeStateProvider).stars} stars. Keep learning!');
  }

  void _onTopicTap(String topicId) {
    final state = ref.read(kidsHomeStateProvider);
    final sid = state.selectedSubject?['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    ref.read(kidsHomeStateProvider.notifier).apply((_) => state.copyWith(
          selectedTopic: state.topics.firstWhere(
            (t) => t['id']?.toString() == topicId,
            orElse: () => state.topics.first,
          ),
        ));
    final topicName = state.topics
            .firstWhere((t) => t['id']?.toString() == topicId,
                orElse: () => state.topics.first)['name']
            ?.toString() ??
        'this topic';
    _mgr.startGenUiLesson(topicName);
  }

  void _onChunkTap(int i) {
    ref
        .read(kidsHomeStateProvider.notifier)
        .apply((s) => s.copyWith(selectedStoryChunk: i));
  }

  void _onStartQuiz() {
    ref
        .read(kidsHomeStateProvider.notifier)
        .apply((s) => s.copyWith(inQuiz: true));
  }

  void _onQuizBack() {
    ref
        .read(kidsHomeStateProvider.notifier)
        .apply((s) => s.copyWith(inQuiz: false));
  }

  void _onListenTap() {
    final state = ref.read(kidsHomeStateProvider);
    if (state.isSpeaking) {
      _tts.stop();
      ref
          .read(kidsHomeStateProvider.notifier)
          .apply((_) => state.copyWith(isSpeaking: false));
    } else {
      _speak(state.currentLesson?['bodyText'] as String? ?? '');
    }
  }

  void _onNextLesson() {
    final state = ref.read(kidsHomeStateProvider);
    final topicName =
        state.selectedTopic?['name']?.toString() ?? 'the next topic';
    _mgr.startGenUiLesson(topicName);
  }

  Future<void> _onQuizComplete(
      {required int correct, required int total}) async {
    final state = ref.read(kidsHomeStateProvider);
    if (state.currentLesson == null) return;
    final firstQ =
        state.quiz.isNotEmpty ? (state.quiz[0] as Map<String, dynamic>?) : null;
    final correctIdx = (firstQ?['correct'] as num?)?.toInt() ?? 0;
    final selectedIdx = correct > 0 ? correctIdx : 99;
    await _mgr.actions.answerQuiz(selectedIdx);
    if (correct / (total > 0 ? total : 1) >= 0.8 && mounted) {
      HapticFeedback.heavyImpact();
      _burstCtrl.forward(from: 0);
      ref
          .read(kidsHomeStateProvider.notifier)
          .apply((s) => s.copyWith(showCorrectBurst: true));
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) {
        ref
            .read(kidsHomeStateProvider.notifier)
            .apply((s) => s.copyWith(showCorrectBurst: false));
      }
      ref.read(kidsHomeStateProvider.notifier).clearSavedState();
    }
  }

  void _onRetryFetchLesson() {
    final state = ref.read(kidsHomeStateProvider);
    final topicName = state.selectedTopic?['name']?.toString() ?? 'this topic';
    _mgr.startGenUiLesson(topicName);
  }

  void _onDismissSessionExpired() {
    ref.read(kidsHomeStateProvider.notifier).dismissExpired();
    context.go('/kids');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(kidAuthStateProvider);
    final theme = Theme.of(context);
    final state = ref.watch(kidsHomeStateProvider);
    if (!auth.isAuthenticated) {
      if (!_redirectScheduled) {
        _redirectScheduled = true;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => context.go('/kids'));
      }
      return const KidsHomeRedirect();
    }
    if (!state.fetchedSubjects) {
      return KidsHomeLoading(onFetchSubjects: () => _mgr.fetchSubjects());
    }
    if (state.sessionExpired) {
      return _SessionExpiredScreen(onDismiss: _onDismissSessionExpired);
    }
    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: KidsHomeAppBar(
            remainingSeconds:
                state.sessionActive ? state.sessionRemaining : null,
          ),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: DesignTokens.durNormal,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: state.selectedSubject == null
                  ? KidsSubjectPickerSection(
                      key: const ValueKey('picker'),
                      auth: auth,
                      state: state,
                      onStarsTap: _onStarsTap,
                      onClaimDailyChest: _mgr.actions.claimDailyChest,
                      onSubjectSelected: _onSubjectPicked,
                    )
                  : KidsLessonViewSection(
                      key: const ValueKey('lesson'),
                      auth: auth,
                      state: state,
                      mgr: _mgr,
                      burstCtrl: _burstCtrl,
                      onBack: () {
                        _stopSessionTimer();
                        ref
                            .read(kidsHomeStateProvider.notifier)
                            .clearSavedState();
                        ref.read(kidsHomeStateProvider.notifier).apply((s) => s
                            .copyWith(
                                selectedSubject: null,
                                selectedTopic: null,
                                currentLesson: null,
                                subjectProgress: null,
                                topics: []));
                      },
                      onTopicTap: _onTopicTap,
                      onReviewTap: () => _mgr.actions.openRoadmapTopicById(
                          state.roadmapSummary?['reviewTopicId']?.toString()),
                      onNextTap: () => _mgr.actions.openRoadmapTopicById(
                          state.roadmapSummary?['nextTopicId']?.toString()),
                      onJourneyTap: () => _mgr.actions.openJourney(auth),
                      onTapTopic: (tid) =>
                          _mgr.actions.openRoadmapTopicById(tid),
                      onTopicRoadmapTap: (tid) =>
                          _mgr.actions.openRoadmapTopicById(tid),
                      onChunkTap: _onChunkTap,
                      onListenTap: _onListenTap,
                      onStartQuiz: _onStartQuiz,
                      onNextLesson: _onNextLesson,
                      onQuizBack: _onQuizBack,
                      onQuizComplete: _onQuizComplete,
                      onRetryFetchLesson: _onRetryFetchLesson,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionExpiredScreen extends StatelessWidget {
  final VoidCallback onDismiss;
  const _SessionExpiredScreen({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: KidsVisualTheme.overlayOn(Theme.of(context)),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Semantics(
                  label: 'Session ended screen',
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Semantics(
                        excludeSemantics: true,
                        child: const Text('⏰', style: TextStyle(fontSize: 80)),
                      ),
                      const SizedBox(height: 20),
                      Semantics(
                        header: true,
                        child: const Text(
                          'Time\u2019s up!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: KidsVisualTheme.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Semantics(
                        liveRegion: true,
                        child: const Text(
                          'Great job today!\nCome back tomorrow for more fun!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: KidsVisualTheme.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Semantics(
                        button: true,
                        label: 'Return to kids home',
                        child: FilledButton.icon(
                          onPressed: onDismiss,
                          icon: const Icon(Icons.home_rounded),
                          label: const Text(' Go home'),
                          style: FilledButton.styleFrom(
                            backgroundColor: KidsVisualTheme.pathBlue,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 16),
                            textStyle: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
