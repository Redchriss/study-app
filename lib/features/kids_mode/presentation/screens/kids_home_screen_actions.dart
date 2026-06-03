import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/theme/design_tokens.dart';
import '../widgets/kid_auth_widgets.dart';
import '../widgets/kids_home_state_provider.dart';
import '../widgets/kids_home_screen_manager.dart';

class KidsHomeScreenActions {
  KidsHomeScreenActions({
    required this.ref,
    required FlutterTts tts,
    required this.mgr,
    required AnimationController burstCtrl,
    required bool Function() isMounted,
    required VoidCallback startSessionTimer,
    required VoidCallback stopSessionTimer,
    required void Function(VoidCallback) setState,
  })  : _tts = tts,
        _burstCtrl = burstCtrl,
        _isMounted = isMounted,
        _startSessionTimer = startSessionTimer,
        _stopSessionTimer = stopSessionTimer,
        _setState = setState;

  final WidgetRef ref;
  final FlutterTts _tts;
  final KidsHomeScreenManager mgr;
  final AnimationController _burstCtrl;
  final bool Function() _isMounted;
  final VoidCallback _startSessionTimer;
  final VoidCallback _stopSessionTimer;
  final void Function(VoidCallback) _setState;

  bool showWarningOverlay = false;

  bool get mounted => _isMounted();

  Future<void> speak(String text) async {
    await _tts.stop();
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
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(mgr.context).showSnackBar(
          const SnackBar(
              content: Text('Reading aloud is not available on this device'),
              backgroundColor: DesignTokens.error),
        );
      }
    }
  }

  void onSubjectPicked(Map<String, dynamic> subject) {
    final sid = subject['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    final auth = ref.read(kidAuthStateProvider);
    ref.read(kidsHomeStateProvider.notifier).apply((s) => s.copyWith(
          selectedSubject: Map<String, dynamic>.from(subject),
          selectedTopic: null,
          topics: [],
          subjectProgress: null,
        ));
    mgr.fetchTopics(sid, auth.standard);
    mgr.fetchSubjectProgress(sid, auth.standard);
    mgr.fetchRoadmap(sid, auth.standard);
    final subjectName = subject['name']?.toString() ?? 'this subject';
    mgr.startGenUiLesson(subjectName);
    _startSessionTimer();
  }

  void onStarsTap(int stars) {
    HapticFeedback.selectionClick();
    speak('You have $stars stars. Keep learning!');
  }

  void onTopicTap(String topicId) {
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
    mgr.startGenUiLesson(topicName);
  }

  void onChunkTap(int i) {
    ref
        .read(kidsHomeStateProvider.notifier)
        .apply((s) => s.copyWith(selectedStoryChunk: i));
  }

  void onStartQuiz() {
    ref
        .read(kidsHomeStateProvider.notifier)
        .apply((s) => s.copyWith(inQuiz: true));
  }

  void onQuizBack() {
    ref
        .read(kidsHomeStateProvider.notifier)
        .apply((s) => s.copyWith(inQuiz: false));
  }

  void onListenTap() {
    final state = ref.read(kidsHomeStateProvider);
    if (state.isSpeaking) {
      _tts.stop();
      ref
          .read(kidsHomeStateProvider.notifier)
          .apply((_) => state.copyWith(isSpeaking: false));
    } else {
      speak(state.currentLesson?['bodyText'] as String? ?? '');
    }
  }

  void onNextLesson() {
    final state = ref.read(kidsHomeStateProvider);
    final topicName =
        state.selectedTopic?['name']?.toString() ?? 'the next topic';
    mgr.startGenUiLesson(topicName);
  }

  Future<void> onQuizComplete(
      {required int correct, required int total}) async {
    final state = ref.read(kidsHomeStateProvider);
    if (state.currentLesson == null) return;
    final firstQ =
        state.quiz.isNotEmpty ? (state.quiz[0] as Map<String, dynamic>?) : null;
    final correctIdx = (firstQ?['correct'] as num?)?.toInt() ?? 0;
    final selectedIdx = correct > 0 ? correctIdx : 99;
    await mgr.actions.answerQuiz(selectedIdx);
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

  void onRetryFetchLesson() {
    final state = ref.read(kidsHomeStateProvider);
    final topicName = state.selectedTopic?['name']?.toString() ?? 'this topic';
    mgr.startGenUiLesson(topicName);
  }

  void onDismissSessionExpired() {
    ref.read(kidsHomeStateProvider.notifier).dismissExpired();
    // context.go('/kids') — handled by caller via callback
  }

  void extendSession() {
    _setState(() => showWarningOverlay = false);
    final notifier = ref.read(kidsHomeStateProvider.notifier);
    notifier.apply((s) => s.copyWith(
          sessionWarningShown: false,
          sessionRemaining:
              (s.sessionRemaining + 300).clamp(0, s.sessionDuration + 300),
          sessionDuration: s.sessionDuration + 300,
        ));
    HapticFeedback.lightImpact();
  }

  void onStopSession() {
    _setState(() => showWarningOverlay = false);
    _stopSessionTimer();
    ref.read(kidsHomeStateProvider.notifier).clearSavedState();
    ref.read(kidsHomeStateProvider.notifier).apply((s) => s.copyWith(
        selectedSubject: null,
        selectedTopic: null,
        currentLesson: null,
        subjectProgress: null,
        topics: []));
  }
}
