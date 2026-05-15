import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';
import '../widgets/kids_daily_goal_ring.dart';
import '../widgets/kids_lesson_step_bar.dart';
import '../widgets/kids_playful_button.dart';
import '../widgets/kids_progress_snapshot_card.dart';
import '../widgets/kids_story_chunk_card.dart';
import '../widgets/kids_subject_card.dart';
import '../widgets/kids_topic_chip.dart';
import 'kid_login_screen.dart';

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});
  @override
  ConsumerState<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen> with SingleTickerProviderStateMixin {
  final _tts = FlutterTts();
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _selectedTopic;
  Map<String, dynamic>? _currentLesson;
  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _topics = [];
  List<dynamic> _quiz = [];
  bool _inQuiz = false;
  int? _quizSelected;
  bool _quizAnswered = false;
  int _quizCorrectIndex = 0;
  bool _isSpeaking = false;
  bool _loading = false;
  int _stars = 0;
  int _streak = 0;
  bool _fetchedSubjects = false;
  bool _showCorrectBurst = false;
  Map<String, dynamic>? _dailySummary;
  Map<String, dynamic>? _subjectProgress;
  int _selectedStoryChunk = 0;
  late final AnimationController _burstCtrl;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    _tts.stop();
    _tts.setCompletionHandler(() {});
    super.dispose();
  }

  GraphQLClient? _kidClient;

  GraphQLClient _buildKidClient() {
    final auth = ref.read(kidAuthStateProvider);
    if (_kidClient != null && auth.token == _kidClientToken) return _kidClient!;
    final link = AuthLink(getToken: () async => auth.token == null ? null : 'Bearer ${auth.token}').concat(HttpLink(AppConfig.graphqlUrl));
    _kidClientToken = auth.token;
    _kidClient = GraphQLClient(cache: GraphQLCache(), link: link);
    return _kidClient!;
  }
  String? _kidClientToken;

  Future<void> _fetchDailySummary() async {
    final auth = ref.read(kidAuthStateProvider);
    if (!auth.isAuthenticated) return;
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(document: gql(kKidDailySummary), fetchPolicy: FetchPolicy.networkOnly));
    if (!mounted || result.data == null) return;
    final s = result.data!['kidDailySummary'] as Map<String, dynamic>?;
    if (s != null) {
      setState(() {
        _dailySummary = Map<String, dynamic>.from(s);
        final ts = (_dailySummary!['totalStars'] as num?)?.toInt();
        if (ts != null) _stars = ts;
      });
    }
  }

  Future<void> _fetchSubjects() async {
    final auth = ref.read(kidAuthStateProvider);
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimarySubjects),
      variables: {'standard': auth.standard, 'educationTrack': auth.educationTrack},
    ));
    if (!mounted) return;
    if (result.data != null) {
      setState(() {
        _subjects = ((result.data!['primarySubjects'] as List?) ?? [])
            .map((s) => Map<String, dynamic>.from(s as Map))
            .toList();
        _fetchedSubjects = true;
      });
      await _fetchDailySummary();
    } else {
      setState(() => _fetchedSubjects = true);
    }
  }

  Future<void> _fetchTopics(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kPrimaryTopics),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (!mounted) return;
    setState(() {
      _topics = ((result.data?['primaryTopics'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (_topics.isEmpty) {
        _selectedTopic = null;
      } else if (_selectedTopic == null || !_topics.any((topic) => topic['id'] == _selectedTopic?['id'])) {
        _selectedTopic = _topics.first;
      }
    });
  }

  Future<void> _fetchSubjectProgress(String subjectId, int standard) async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(
      document: gql(kKidProgress),
      variables: {'subjectId': subjectId, 'standard': standard},
      fetchPolicy: FetchPolicy.networkOnly,
    ));
    if (!mounted) return;
    final progress = result.data?['kidProgress'];
    setState(() {
      _subjectProgress = progress is Map ? Map<String, dynamic>.from(progress) : null;
    });
  }

  Future<void> _claimDailyChest() async {
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(document: gql(kClaimKidDailyChest)));
    final payload = result.data?['claimKidDailyChest'] as Map<String, dynamic>?;
    if (payload?['success'] == true && mounted) {
      HapticFeedback.heavyImpact();
      final s = payload!['summary'] as Map<String, dynamic>?;
      if (s != null) {
        setState(() {
          _dailySummary = Map<String, dynamic>.from(s);
          final ts = (_dailySummary!['totalStars'] as num?)?.toInt();
          if (ts != null) _stars = ts;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You earned bonus stars!'), backgroundColor: DesignTokens.success),
      );
    } else if (mounted) {
      final errs = (payload?['errors'] as List?)?.cast<String>() ?? const ['Try again later'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errs.join(', '))));
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    try {
      await _tts.speak(text.replaceAll('\n', ' ').replaceAll(RegExp(r'\{[^}]*\}'), ''));
    } catch (_) {
      if (mounted) {
        setState(() => _isSpeaking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reading aloud is not available on this device'),
            backgroundColor: DesignTokens.error,
          ),
        );
      }
    }
  }

  Future<void> _fetchLesson(String subjectId, int standard, {String? topicId}) async {
    setState(() => _loading = true);
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kFetchKidLesson),
      variables: {'subjectId': subjectId, 'standard': standard, 'topicId': topicId, 'language': 'english'},
    ));
    if (!mounted) return;
    if (result.data != null) {
      final data = result.data!['fetchKidLesson'];
      if (data['success'] == true) {
        setState(() {
          _currentLesson = data['lesson'];
          _quiz = (_currentLesson?['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _inQuiz = false;
          _quizAnswered = false;
          _quizSelected = null;
          _selectedStoryChunk = 0;
          _loading = false;
        });
      } else {
        final errs = (data['errors'] as List?)?.cast<String>() ?? const ['Could not load lesson'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errs.join(', '))));
      }
      await _fetchDailySummary();
      await _fetchSubjectProgress(subjectId, standard);
    }
    setState(() => _loading = false);
  }

  List<String> _lessonChunks(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
  }

  void _startQuiz() {
    if (_quiz.isEmpty) return;
    final q = _quiz[0];
    setState(() {
      _quizCorrectIndex = q['correct'] as int? ?? 0;
      _inQuiz = true;
      _quizAnswered = false;
      _quizSelected = null;
    });
    HapticFeedback.mediumImpact();
    _speak(q['question'] as String? ?? '');
  }

  Future<void> _answerQuiz(int idx) async {
    if (_quizAnswered || _currentLesson == null) return;
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kAnswerKidQuiz),
      variables: {'lessonId': _currentLesson!['id'], 'selectedIndex': idx},
    ));
    final payload = result.data?['answerKidQuiz'] as Map<String, dynamic>?;
    final correct = payload?['correct'] == true;
    if (payload?['success'] == false && mounted) {
      final errs = (payload?['errors'] as List?)?.cast<String>() ?? const ['Could not save answer'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errs.join(', '))));
      return;
    }
    if (!mounted) return;
    setState(() {
      _quizSelected = idx;
      _quizAnswered = true;
      _stars = (payload?['starsEarned'] as num?)?.toInt() ?? _stars;
      _streak = (payload?['streak'] as num?)?.toInt() ?? _streak;
    });
    if (correct) {
      HapticFeedback.heavyImpact();
      _burstCtrl.forward(from: 0);
      setState(() => _showCorrectBurst = true);
      await Future.delayed(const Duration(milliseconds: 850));
      if (mounted) setState(() => _showCorrectBurst = false);
      _speak('Correct! Well done!');
    } else {
      HapticFeedback.selectionClick();
      _speak('Nice try! The right answer is highlighted.');
    }
    await _fetchDailySummary();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(kidAuthStateProvider);
    final theme = Theme.of(context);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/kids'));
      return const Scaffold(body: Center(child: Text('Redirecting...')));
    }
    if (!_fetchedSubjects) {
      _fetchSubjects();
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

    return Theme(
      data: KidsVisualTheme.overlayOn(theme),
      child: Container(
        decoration: BoxDecoration(gradient: KidsVisualTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: DesignTokens.shadowSm(theme.brightness == Brightness.dark),
                  ),
                  child: const Icon(Icons.school_rounded, color: KidsVisualTheme.pathBlue, size: 22),
                ),
                const SizedBox(width: 10),
                const Text('Yaza Kids'),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(kidAuthStateProvider.notifier).state = const KidAuthState();
                      context.go('/kids');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Text('Switch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: AnimatedSwitcher(
              duration: DesignTokens.durNormal,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _selectedSubject == null
                  ? KeyedSubtree(key: const ValueKey('picker'), child: _buildPicker(auth))
                  : KeyedSubtree(key: const ValueKey('lesson'), child: _buildLesson(auth)),
            ),
          ),
        ),
      ),
    );
  }

  String _mascotMessage(KidAuthState auth) {
    final act = (_dailySummary?['activitiesToday'] as num?)?.toInt() ?? 0;
    final goal = (_dailySummary?['dailyGoal'] as num?)?.toInt() ?? 3;
    if (act >= goal) {
      return 'Today’s goal is complete. You can still play lessons—or rest. Both are great!';
    }
    final left = goal - act;
    final unit = left == 1 ? 'step' : 'steps';
    final track = auth.educationTrack == 'ecd' ? 'Little learner' : 'Super learner';
    return '$track, only $left small $unit left to fill today’s ring.';
  }

  Widget _buildPicker(KidAuthState auth) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KidsHeroCard(
            childName: auth.childName,
            standard: auth.standard,
            educationTrack: auth.educationTrack,
            summary: _dailySummary,
            quizHotStreak: _streak,
            stars: _stars,
            onStarsTap: () {
              HapticFeedback.selectionClick();
              _speak('You have $_stars stars. Keep learning!');
            },
          ),
          const SizedBox(height: 12),
          KidsMascotHint(message: _mascotMessage(auth)),
          const SizedBox(height: 12),
          if (_dailySummary != null)
            Align(
              alignment: Alignment.centerLeft,
              child: KidsDailyChestChip(
                available: _dailySummary!['chestAvailable'] == true,
                claimed: _dailySummary!['chestClaimed'] == true,
                onClaim: _claimDailyChest,
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
          if (_subjects.isEmpty)
            _KidsEmptySubjects()
          else
            ..._subjects.map((s) {
              final name = s['name'] as String? ?? '';
              final c = _kidsSubjectColor(name);
              final icon = _kidsSubjectIcon(name);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: KidsSubjectCard(
                  name: name,
                  accent: c,
                  icon: icon,
                  onTap: () {
                    final nextSubject = Map<String, dynamic>.from(s);
                    setState(() {
                      _selectedSubject = nextSubject;
                      _selectedTopic = null;
                      _topics = [];
                      _subjectProgress = null;
                    });
                    final subjectId = nextSubject['id']?.toString();
                    if (subjectId != null && subjectId.isNotEmpty) {
                      _fetchTopics(subjectId, auth.standard);
                      _fetchSubjectProgress(subjectId, auth.standard);
                      _fetchLesson(subjectId, auth.standard);
                    }
                  },
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLesson(KidAuthState auth) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_currentLesson == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No lesson yet — tap Next to try again',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.95), fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      );
    }
    final text = _currentLesson!['bodyText'] as String? ?? '';
    final chunks = _lessonChunks(text);
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
                        onTap: () {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedSubject = null;
                            _selectedTopic = null;
                            _currentLesson = null;
                            _subjectProgress = null;
                            _topics = [];
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded, color: KidsVisualTheme.pathBlue, size: 22),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      auth.childName,
                      style: const TextStyle(
                        color: KidsVisualTheme.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_topics.isNotEmpty) ...[
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _topics.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final topic = _topics[index];
                        final selected = topic['id'] == _selectedTopic?['id'];
                        return KidsTopicChip(
                          label: topic['name']?.toString() ?? 'Topic',
                          selected: selected,
                          onTap: () {
                            final subjectId = _selectedSubject?['id']?.toString();
                            final topicId = topic['id']?.toString();
                            if (subjectId == null || topicId == null) return;
                            setState(() => _selectedTopic = topic);
                            _fetchLesson(subjectId, auth.standard, topicId: topicId);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_subjectProgress != null) ...[
                  KidsProgressSnapshotCard(
                    lessonsCompleted: (_subjectProgress?['lessonsCompleted'] as num?)?.toInt() ?? 0,
                    quizzesTaken: (_subjectProgress?['quizzesTaken'] as num?)?.toInt() ?? 0,
                    quizzesCorrect: (_subjectProgress?['quizzesCorrect'] as num?)?.toInt() ?? 0,
                    starsEarned: (_subjectProgress?['starsEarned'] as num?)?.toInt() ?? 0,
                  ),
                  const SizedBox(height: 14),
                ],
                KidsLessonStepBar(inQuiz: _inQuiz),
                const SizedBox(height: 18),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _KidsFloatingPanel(
                      child: _inQuiz ? _buildQuizContent(Theme.of(context)) : _buildStoryPanel(text, chunks),
                    ),
                    if (_showCorrectBurst) _CorrectBurstOverlay(controller: _burstCtrl),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: KidsPlayfulPrimaryButton(
                        label: 'Next lesson',
                        icon: Icons.auto_awesome,
                        onTap: () {
                          final subjectId = _selectedSubject?['id']?.toString();
                          if (subjectId != null && subjectId.isNotEmpty) {
                            _fetchLesson(
                              subjectId,
                              auth.standard,
                              topicId: _selectedTopic?['id']?.toString(),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: KidsPlayfulSecondaryButton(
                        icon: Icons.replay_rounded,
                        label: 'Try quiz again',
                        color: const Color(0xFF9B59B6),
                        onTap: _quiz.isNotEmpty ? _startQuiz : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoryPanel(String text, List<String> chunks) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: KidsVisualTheme.ctaGradient,
            shape: BoxShape.circle,
            boxShadow: KidsVisualTheme.chunkyShadow(const Color(0xFF2A8F4A), dy: 3),
          ),
          child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          _currentLesson?['title']?.toString() ?? 'Lesson',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: KidsVisualTheme.ink,
          ),
          textAlign: TextAlign.center,
        ),
        if (_selectedTopic?['name'] != null) ...[
          const SizedBox(height: 8),
          Text(
            _selectedTopic!['name'].toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: KidsVisualTheme.inkMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        ...chunks.asMap().entries.map((entry) {
          final index = entry.key;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: KidsStoryChunkCard(
              index: index,
              text: entry.value,
              selected: _selectedStoryChunk == index,
              onTap: () => setState(() => _selectedStoryChunk = index),
            ),
          );
        }),
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [
            KidsPlayfulSecondaryButton(
              icon: _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
              label: _isSpeaking ? 'Stop' : 'Listen',
              color: KidsVisualTheme.pathBlue,
              onTap: () {
                if (_isSpeaking) {
                  _tts.stop();
                  setState(() => _isSpeaking = false);
                } else {
                  final playableText = chunks.isEmpty
                      ? text
                      : chunks[_selectedStoryChunk.clamp(0, chunks.length - 1)];
                  _speak(playableText);
                }
              },
            ),
            KidsPlayfulSecondaryButton(
              icon: Icons.quiz_rounded,
              label: 'Quiz time!',
              color: const Color(0xFF9B59B6),
              onTap: _quiz.isNotEmpty ? _startQuiz : null,
            ),
          ],
        ),
        if (_streak > 0) ...[
          const SizedBox(height: 16),
          _StreakChip(streak: _streak, quizMode: true),
        ],
      ],
    );
  }

  Widget _buildQuizContent(ThemeData theme) {
    if (_quiz.isEmpty) return const SizedBox();
    final q = _quiz[0];
    final question = q['question'] as String? ?? '';
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    return Column(
      children: [
        Material(
          color: KidsVisualTheme.sunGold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _speak(question),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: KidsVisualTheme.ink),
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, color: KidsVisualTheme.pathBlue, size: 26),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...options.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          Color bg = Colors.white;
          Color fg = KidsVisualTheme.ink;
          double borderW = 2;
          Color borderC = KidsVisualTheme.ink.withValues(alpha: 0.08);
          if (_quizAnswered) {
            if (idx == _quizCorrectIndex) {
              bg = DesignTokens.success;
              fg = Colors.white;
              borderC = DesignTokens.success;
            } else if (idx == _quizSelected) {
              bg = DesignTokens.error;
              fg = Colors.white;
              borderC = DesignTokens.error;
            }
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _quizAnswered ? null : () => _answerQuiz(idx),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderC, width: borderW),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: _quizAnswered && idx == _quizCorrectIndex ? 0.25 : 0.95),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(fontWeight: FontWeight.w900, color: fg, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(opt, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: fg))),
                      if (_quizAnswered && idx == _quizCorrectIndex)
                        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 26),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        if (_quizAnswered) ...[
          const SizedBox(height: 8),
          KidsPlayfulPrimaryButton(
            label: 'Back to story',
            onTap: () => setState(() {
              _inQuiz = false;
              _quizAnswered = false;
              _quizSelected = null;
            }),
          ),
        ],
      ],
    );
  }
}

class _KidsHeroCard extends StatelessWidget {
  const _KidsHeroCard({
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
                  _StreakChip(streak: quizHotStreak, compact: true, quizMode: true),
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

class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak, this.compact = false, this.quizMode = false});

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

class _KidsEmptySubjects extends StatelessWidget {
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

class _KidsFloatingPanel extends StatelessWidget {
  const _KidsFloatingPanel({required this.child});

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

class _CorrectBurstOverlay extends StatelessWidget {
  const _CorrectBurstOverlay({required this.controller});

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

Color _kidsSubjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english':
      return KidsVisualTheme.pathBlue;
    case 'chichewa':
      return KidsVisualTheme.trailGreen;
    case 'mathematics':
      return KidsVisualTheme.sunGold;
    case 'science':
      return const Color(0xFF8E44AD);
    case 'social studies':
      return DesignTokens.error;
    default:
      return DesignTokens.primary;
  }
}

IconData _kidsSubjectIcon(String name) {
  switch (name.toLowerCase()) {
    case 'english':
      return Icons.abc_rounded;
    case 'chichewa':
      return Icons.translate_rounded;
    case 'mathematics':
      return Icons.calculate_rounded;
    case 'science':
      return Icons.science_rounded;
    case 'social studies':
      return Icons.public_rounded;
    default:
      return Icons.menu_book_rounded;
  }
}
