import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import 'kid_login_screen.dart';

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});
  @override
  ConsumerState<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen> {
  final _tts = FlutterTts();
  Map<String, dynamic>? _selectedSubject;
  Map<String, dynamic>? _currentLesson;
  List<Map<String, dynamic>> _subjects = [];
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

  @override
  void initState() {
    super.initState();
    _tts.setSpeechRate(0.45);
    _tts.setVolume(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _tts.setCompletionHandler(() {});
    super.dispose();
  }

  GraphQLClient _buildKidClient() {
    final auth = ref.read(kidAuthStateProvider);
    final link = AuthLink(getToken: () => auth.token).concat(HttpLink(AppConfig.graphqlUrl));
    return GraphQLClient(cache: GraphQLCache(), link: link);
  }

  Future<void> _fetchSubjects() async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(document: gql(kPrimarySubjects)));
    if (result.data != null && mounted) {
      setState(() {
        _subjects = ((result.data!['primarySubjects'] as List?) ?? []).map((s) => Map<String, dynamic>.from(s as Map)).toList();
        _fetchedSubjects = true;
      });
    } else {
      setState(() => _fetchedSubjects = true);
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    setState(() => _isSpeaking = true);
    try {
      await _tts.speak(text.replaceAll('\n', ' ').replaceAll(RegExp(r'\{[^}]*\}'), ''));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('TTS unavailable on this device'), backgroundColor: DesignTokens.error),
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
    if (result.data != null && mounted) {
      final data = result.data!['fetchKidLesson'];
      if (data['success'] == true) {
        setState(() {
          _currentLesson = data['lesson'];
          _quiz = (_currentLesson?['quiz'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _inQuiz = false; _quizAnswered = false; _quizSelected = null; _loading = false;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  void _startQuiz() {
    if (_quiz.isEmpty) return;
    final q = _quiz[0];
    setState(() { _quizCorrectIndex = q['correct'] as int? ?? 0; _inQuiz = true; _quizAnswered = false; _quizSelected = null; });
    _speak(q['question'] as String? ?? '');
  }

  Future<void> _answerQuiz(int idx) async {
    if (_quizAnswered || _currentLesson == null) return;
    final c = _buildKidClient();
    final result = await c.mutate(MutationOptions(
      document: gql(kAnswerKidQuiz),
      variables: {'lessonId': _currentLesson!['id'], 'selectedIndex': idx},
    ));
    final correct = result.data?['answerKidQuiz']?['correct'] == true;
    setState(() {
      _quizSelected = idx; _quizAnswered = true;
      _stars = result.data?['answerKidQuiz']?['starsEarned'] ?? _stars;
      _streak = result.data?['answerKidQuiz']?['streak'] ?? _streak;
    });
    _speak(correct ? 'Correct! Well done!' : 'Not quite. Try the next one!');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(kidAuthStateProvider);
    final theme = Theme.of(context);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/kids'));
      return const Scaffold(body: Center(child: Text('Redirecting...')));
    }
    if (!_fetchedSubjects) { _fetchSubjects(); return const Scaffold(body: Center(child: CircularProgressIndicator())); }
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.auto_awesome, color: DesignTokens.warning, size: 20),
          const SizedBox(width: 6),
          Text('Yaza Kids', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        ]),
        actions: [
          GestureDetector(
            onTap: () { ref.read(kidAuthStateProvider.notifier).state = const KidAuthState(); context.go('/kids'); },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: DesignTokens.textTertiary.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
              child: const Text('Switch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      body: _selectedSubject == null ? _buildPicker() : _buildLesson(),
    );
  }

  Widget _buildPicker() {
    final theme = Theme.of(context);
    final auth = ref.read(kidAuthStateProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spMd),
      child: Column(
        children: [
          GlassCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Hi ${auth.childName}! ⭐', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  Text('Standard ${auth.standard}', style: const TextStyle(color: DesignTokens.textSecondary)),
                ]),
                GestureDetector(
                  onTap: () => _speak('You have $_stars stars!'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(color: DesignTokens.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                    child: Row(children: [
                      const Icon(Icons.star, color: DesignTokens.warning, size: 20),
                      const SizedBox(width: 4),
                      Text('$_stars', style: const TextStyle(fontWeight: FontWeight.w800, color: DesignTokens.warning)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: DesignTokens.spLg),
          const SectionHeader(title: 'Pick a subject'),
          const SizedBox(height: DesignTokens.spSm),
          ...(_subjects.isEmpty ? [
            Container(
              padding: const EdgeInsets.all(DesignTokens.spXl),
              decoration: BoxDecoration(
                color: DesignTokens.surfaceVariant, borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
              ),
              child: const Center(child: Text('No subjects loaded', style: TextStyle(color: DesignTokens.textSecondary))),
            )
          ] : _subjects.map((s) {
            final name = s['name'] as String? ?? '';
            final c = _kidsSubjectColor(name);
            final icon = _kidsSubjectIcon(name);
            return Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spSm),
              child: AnimatedPress(
                onTap: () {
                  setState(() => _selectedSubject = Map<String, dynamic>.from(s));
                  _fetchLesson(s['id'], auth.standard);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd, vertical: DesignTokens.spSm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    border: Border.all(color: c.withValues(alpha: 0.3)),
                    boxShadow: DesignTokens.shadowSm(Theme.of(context).brightness == Brightness.dark),
                  ),
                  child: Row(children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                      child: Icon(icon, color: c, size: 24),
                    ),
                    const SizedBox(width: DesignTokens.spMd),
                    Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            );
          })),
        ],
      ),
    );
  }

  Widget _buildLesson() {
    final theme = Theme.of(context);
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_currentLesson == null) return const Center(child: Text('No lesson available'));
    final text = _currentLesson!['bodyText'] as String? ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DesignTokens.spMd),
      child: Column(children: [
        Row(children: [
          AnimatedPress(
            onTap: () => setState(() => _selectedSubject = null),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.arrow_back, size: 18, color: DesignTokens.primary),
            ),
          ),
          const Spacer(),
          Text(ref.read(kidAuthStateProvider).childName, style: const TextStyle(color: DesignTokens.textSecondary, fontSize: 14)),
        ]),
        const SizedBox(height: DesignTokens.spMd),
        if (_inQuiz) ...[
          GlassCard(child: _buildQuizContent(theme))
        ] else ...[
          GlassCard(child: Column(children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(color: DesignTokens.primaryLight.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.auto_stories, size: 32, color: DesignTokens.primaryLight),
            ),
            const SizedBox(height: DesignTokens.spMd),
            Text(text, style: const TextStyle(fontSize: 22, height: 1.6, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: DesignTokens.spLg),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _KidButton(icon: _isSpeaking ? Icons.stop : Icons.volume_up, label: _isSpeaking ? 'Stop' : 'Listen', color: DesignTokens.success, onTap: () {
                if (_isSpeaking) { _tts.stop(); setState(() => _isSpeaking = false); } else { _speak(text); }
              }),
              const SizedBox(width: DesignTokens.spSm),
              _KidButton(icon: Icons.quiz_outlined, label: 'Quiz', color: DesignTokens.secondary, onTap: _quiz.isNotEmpty ? _startQuiz : null),
            ]),
          ])),
          if (_streak >= 2) ...[
            const SizedBox(height: DesignTokens.spSm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: DesignTokens.warning.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.local_fire_department, color: DesignTokens.secondary, size: 20),
                const SizedBox(width: 6),
                Text('$_streak streak!', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: DesignTokens.secondary)),
              ]),
            ),
          ],
        ],
        const SizedBox(height: DesignTokens.spSm),
        AnimatedPress(
          onTap: () => _fetchLesson(_selectedSubject!['id']!, ref.read(kidAuthStateProvider).standard),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: DesignTokens.primary, borderRadius: BorderRadius.circular(16)),
            child: const Text('Next Lesson', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _buildQuizContent(ThemeData theme) {
    if (_quiz.isEmpty) return const SizedBox();
    final q = _quiz[0];
    final question = q['question'] as String? ?? '';
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    return Column(children: [
      GestureDetector(
        onTap: () => _speak(question),
        child: Container(
          width: double.infinity, padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: DesignTokens.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Flexible(child: Text(question, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
            const SizedBox(width: 8), const Icon(Icons.volume_up, color: DesignTokens.secondary, size: 22),
          ]),
        ),
      ),
      const SizedBox(height: DesignTokens.spMd),
      ...options.asMap().entries.map((e) {
        final idx = e.key; final opt = e.value;
        Color bg = DesignTokens.surfaceVariant; Color fg = DesignTokens.textPrimary;
        if (_quizAnswered) {
          if (idx == _quizCorrectIndex) { bg = DesignTokens.success; fg = Colors.white; }
          else if (idx == _quizSelected) { bg = DesignTokens.error; fg = Colors.white; }
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spXs),
          child: AnimatedPress(
            onTap: () => _answerQuiz(idx),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _quizAnswered && idx == _quizCorrectIndex ? DesignTokens.success : Colors.transparent, width: 2)),
              child: Row(children: [
                Container(width: 32, height: 32,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: Center(child: Text(String.fromCharCode(65 + idx), style: TextStyle(fontWeight: FontWeight.w800, color: fg)))),
                const SizedBox(width: DesignTokens.spSm),
                Expanded(child: Text(opt, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: fg))),
                if (_quizAnswered && idx == _quizCorrectIndex) const Icon(Icons.check_circle, color: Colors.white, size: 24),
              ]),
            ),
          ),
        );
      }),
      if (_quizAnswered) ...[
        const SizedBox(height: DesignTokens.spSm),
        AnimatedPress(
          onTap: () => setState(() { _inQuiz = false; _quizAnswered = false; _quizSelected = null; }),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(color: DesignTokens.primary, borderRadius: BorderRadius.circular(16)),
            child: const Text('Continue', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    ]);
  }
}

Color _kidsSubjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english': return DesignTokens.primaryLight;
    case 'chichewa': return DesignTokens.success;
    case 'mathematics': return DesignTokens.warning;
    case 'science': return const Color(0xFF8E44AD);
    case 'social studies': return DesignTokens.error;
    default: return DesignTokens.primary;
  }
}

IconData _kidsSubjectIcon(String name) {
  switch (name.toLowerCase()) {
    case 'english': return Icons.abc;
    case 'chichewa': return Icons.translate;
    case 'mathematics': return Icons.calculate;
    case 'science': return Icons.biotech;
    case 'social studies': return Icons.public;
    default: return Icons.book;
  }
}

class _KidButton extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback? onTap;
  const _KidButton({required this.icon, required this.label, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: onTap != null ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: onTap != null ? 0.3 : 0.1)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color.withValues(alpha: onTap != null ? 1.0 : 0.4), size: 20),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color.withValues(alpha: onTap != null ? 1.0 : 0.4))),
        ]),
      ),
    );
  }
}
