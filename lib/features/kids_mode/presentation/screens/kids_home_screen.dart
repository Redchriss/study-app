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
import '../widgets/kids_lesson_view_section.dart';
import '../widgets/kids_subject_picker_section.dart';

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});
  @override
  ConsumerState<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen>
    with SingleTickerProviderStateMixin {
  final _mgr = KidsHomeScreenManager();
  final _tts = FlutterTts();
  bool _redirectScheduled = false;

  @override
  void initState() {
    super.initState();
    _mgr.attach(
        ref: ref,
        setState: setState,
        getContext: () => context,
        isMounted: () => mounted);
    _mgr.data.burstCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _mgr.data.isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _mgr.data.burstCtrl.dispose();
    _tts.stop();
    _tts.setCompletionHandler(() {});
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    if (!mounted) return;
    setState(() => _mgr.data.isSpeaking = true);
    try {
      await _tts.speak(
          text.replaceAll('\n', ' ').replaceAll(RegExp(r'\{[^}]*\}'), ''));
    } catch (_) {
      if (mounted) {
        setState(() => _mgr.data.isSpeaking = false);
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
    setState(() {
      _mgr.data.selectedSubject = Map<String, dynamic>.from(subject);
      _mgr.data.selectedTopic = null;
      _mgr.data.topics = [];
      _mgr.data.subjectProgress = null;
    });
    _mgr.fetchTopics(sid, auth.standard);
    _mgr.fetchSubjectProgress(sid, auth.standard);
    _mgr.fetchRoadmap(sid, auth.standard);
    _mgr.fetchLesson(sid, auth.standard);
  }

  void _onStarsTap() {
    HapticFeedback.selectionClick();
    _speak('You have ${_mgr.data.stars} stars. Keep learning!');
  }

  void _onTopicTap(String topicId) {
    final sid = _mgr.data.selectedSubject?['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    setState(() {
      _mgr.data.selectedTopic = _mgr.data.topics.firstWhere(
        (t) => t['id']?.toString() == topicId,
        orElse: () => _mgr.data.topics.first,
      );
    });
    _mgr.fetchLesson(sid, ref.read(kidAuthStateProvider).standard,
        topicId: topicId);
  }

  void _onChunkTap(int i) => setState(() => _mgr.data.selectedStoryChunk = i);
  void _onStartQuiz() => setState(() => _mgr.data.inQuiz = true);
  void _onQuizBack() => setState(() => _mgr.data.inQuiz = false);

  void _onListenTap() {
    if (_mgr.data.isSpeaking) {
      _tts.stop();
      setState(() => _mgr.data.isSpeaking = false);
    } else {
      _speak(_mgr.data.currentLesson?['bodyText'] as String? ?? '');
    }
  }

  void _onNextLesson() {
    final sid = _mgr.data.selectedSubject?['id']?.toString();
    if (sid != null && sid.isNotEmpty) {
      _mgr.fetchLesson(sid, ref.read(kidAuthStateProvider).standard,
          topicId: _mgr.data.selectedTopic?['id']?.toString());
    }
  }

  Future<void> _onQuizComplete(
      {required int correct, required int total}) async {
    if (_mgr.data.currentLesson == null) return;
    final firstQ = _mgr.data.quiz.isNotEmpty
        ? (_mgr.data.quiz[0] as Map<String, dynamic>?)
        : null;
    final correctIdx = (firstQ?['correct'] as num?)?.toInt() ?? 0;
    final selectedIdx = correct > 0 ? correctIdx : 99;
    await _mgr.answerQuiz(selectedIdx);
    if (correct / (total > 0 ? total : 1) >= 0.8 && mounted) {
      HapticFeedback.heavyImpact();
      _mgr.data.burstCtrl.forward(from: 0);
      setState(() => _mgr.data.showCorrectBurst = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() => _mgr.data.showCorrectBurst = false);
    }
  }

  void _onRetryFetchLesson() {
    final sid = _mgr.data.selectedSubject?['id']?.toString();
    if (sid == null || sid.isEmpty) return;
    final auth = ref.read(kidAuthStateProvider);
    _mgr.fetchLesson(sid, auth.standard,
        topicId: _mgr.data.selectedTopic?['id']?.toString() ??
            _mgr.data.selectedTopic?['topicId']?.toString());
  }

  Widget _buildRedirect() {
    if (!_redirectScheduled) {
      _redirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/kids');
      });
    }
    return const Scaffold(body: Center(child: Text('Redirecting...')));
  }

  Widget _buildLoading(ThemeData theme) {
    if (!_mgr.data.subjectFetchStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !_mgr.data.fetchedSubjects &&
            !_mgr.data.subjectFetchStarted) { _mgr.fetchSubjects(); }
      });
    }
    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: const Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(kidAuthStateProvider);
    final theme = Theme.of(context);
    final d = _mgr.data;
    if (!auth.isAuthenticated) return _buildRedirect();
    if (!d.fetchedSubjects) return _buildLoading(theme);
    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const KidsHomeAppBar(),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: DesignTokens.durNormal,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: d.selectedSubject == null
                  ? KidsSubjectPickerSection(
                      key: const ValueKey('picker'),
                      auth: auth,
                      data: d,
                      onStarsTap: _onStarsTap,
                      onClaimDailyChest: _mgr.claimDailyChest,
                      onSubjectSelected: _onSubjectPicked,
                    )
                  : KidsLessonViewSection(
                      key: const ValueKey('lesson'),
                      auth: auth,
                      data: d,
                      onBack: () => setState(() {
                        d.selectedSubject = d.selectedTopic =
                            d.currentLesson = d.subjectProgress = null;
                        d.topics = [];
                      }),
                      onTopicTap: _onTopicTap,
                      onReviewTap: () => _mgr.openRoadmapTopicById(
                          d.roadmapSummary?['reviewTopicId']?.toString()),
                      onNextTap: () => _mgr.openRoadmapTopicById(
                          d.roadmapSummary?['nextTopicId']?.toString()),
                      onJourneyTap: () => _mgr.openJourney(auth),
                      onTapTopic: (tid) => _mgr.openRoadmapTopicById(tid),
                      onTopicRoadmapTap: (tid) =>
                          _mgr.openRoadmapTopicById(tid),
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
