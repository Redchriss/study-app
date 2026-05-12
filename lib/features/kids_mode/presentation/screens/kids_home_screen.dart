import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/config/app_config.dart';
import 'kid_login_screen.dart';

final _standards = [1, 2, 3, 4, 5, 6, 7, 8];

class KidsHomeScreen extends ConsumerStatefulWidget {
  const KidsHomeScreen({super.key});
  @override
  ConsumerState<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends ConsumerState<KidsHomeScreen> {
  final _tts = FlutterTts();
  int? _selectedStandard;
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

  Future<void> _ensureClient() async {
    if (_fetchedSubjects) return;
    await _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    final c = _buildKidClient();
    final result = await c.query(QueryOptions(document: gql(kPrimarySubjects)));
    if (result.data != null && mounted) {
      final subs = (result.data!['primarySubjects'] as List?) ?? [];
      setState(() {
        _subjects = subs.map((s) => Map<String, dynamic>.from(s as Map)).toList();
        _fetchedSubjects = true;
      });
    } else {
      setState(() => _fetchedSubjects = true);
    }
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    setState(() => _isSpeaking = true);
    await _tts.speak(text.replaceAll('\n', ' ').replaceAll(RegExp(r'\{[^}]*\}'), ''));
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
          _quiz = jsonDecode(jsonEncode(_currentLesson?['quiz'] ?? []));
          _inQuiz = false;
          _quizAnswered = false;
          _quizSelected = null;
          _loading = false;
        });
      }
    }
    if (mounted) setState(() => _loading = false);
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
      _quizSelected = idx;
      _quizAnswered = true;
      _stars = result.data?['answerKidQuiz']?['starsEarned'] ?? _stars;
      _streak = result.data?['answerKidQuiz']?['streak'] ?? _streak;
    });
    _speak(correct ? 'Correct! Well done!' : 'Not quite. Try the next one!');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(kidAuthStateProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/kids'));
      return const Scaffold(body: Center(child: Text('Redirecting...')));
    }
    if (_selectedStandard == null) {
      _ensureClient();
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: SafeArea(
        child: _selectedSubject == null ? _buildPicker() : _buildLesson(),
      ),
    );
  }

  Widget _buildPicker() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('⭐ ${ref.read(kidAuthStateProvider).childName}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _speak('You have $_stars stars!'),
                    child: Row(children: [
                      const Icon(Icons.star, color: Color(0xFFF1C40F), size: 28),
                      Text(' $_stars', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () { ref.read(kidAuthStateProvider.notifier).state = const KidAuthState(); context.go('/kids'); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                      child: const Text('Switch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Pick a subject', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else ...[
            ...(_buildSubjectList()),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildSubjectList() {
    final auth = ref.read(kidAuthStateProvider);
    if (_subjects.isEmpty) {
      return [
        Text('Standard ${auth.standard}', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        const SizedBox(height: 20),
        const Center(child: Text('No subjects available')),
      ];
    }
    return [
      Text('Standard ${auth.standard}', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
      const SizedBox(height: 20),
      ..._subjects.map((s) {
        final name = s['name'] as String? ?? '';
        final subjectId = s['id'] as String? ?? '';
        final color = _subjectColor(name);
        final icon = _subjectIcon(name);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedSubject = Map<String, dynamic>.from(s));
              _fetchLesson(subjectId, auth.standard);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withOpacity(0.3), width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
                    child: Icon(icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        );
      }),
    ];
  }

  Widget _buildLesson() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating your lesson...', style: TextStyle(fontSize: 18)),
          ],
        ),
      );
    }
    if (_currentLesson == null) {
      return const Center(child: Text('No lesson available'));
    }
    final text = _currentLesson!['bodyText'] as String? ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedSubject = null),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90D9).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF4A90D9)),
                ),
              ),
              const Spacer(),
              Text(ref.read(kidAuthStateProvider).childName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),
          if (_inQuiz) ...[
            _buildQuizCard(),
          ] else ...[
            _buildLessonCard(text),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonCard(String text) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90D9).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.auto_stories, size: 36, color: Color(0xFF4A90D9)),
              ),
              const SizedBox(height: 24),
              Text(text, style: const TextStyle(fontSize: 24, height: 1.6, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: _isSpeaking ? Icons.stop : Icons.volume_up,
                    label: _isSpeaking ? 'Stop' : 'Listen', color: const Color(0xFF27AE60),
                    onTap: () {
                      if (_isSpeaking) { _tts.stop(); setState(() => _isSpeaking = false); }
                      else { _speak(text); }
                    },
                  ),
                  const SizedBox(width: 20),
                  _ActionButton(
                    icon: Icons.quiz_outlined, label: 'Quiz', color: const Color(0xFFE67E22),
                    onTap: _quiz.isNotEmpty ? _startQuiz : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ActionButton(
              icon: Icons.arrow_forward, label: 'Next', color: const Color(0xFF4A90D9),
              onTap: () => _fetchLesson(_selectedSubject!['id']!, ref.read(kidAuthStateProvider).standard),
            ),
            const SizedBox(width: 16),
            if (_streak >= 2)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1C40F).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, color: Color(0xFFE67E22), size: 22),
                    const SizedBox(width: 6),
                    Text('$_streak', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFFE67E22))),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuizCard() {
    if (_quiz.isEmpty) return const SizedBox();
    final q = _quiz[0];
    final question = q['question'] as String? ?? '';
    final options = (q['options'] as List?)?.cast<String>() ?? [];
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: const Color(0xFFE67E22).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => _speak(question),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9E7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text(question, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center)),
                      const SizedBox(width: 8),
                      const Icon(Icons.volume_up, color: Color(0xFFE67E22), size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ...options.asMap().entries.map((e) {
                final idx = e.key;
                final opt = e.value;
                Color bg = const Color(0xFFF0F0F0);
                Color fg = Colors.black87;
                if (_quizAnswered) {
                  if (idx == _quizCorrectIndex) { bg = const Color(0xFF27AE60); fg = Colors.white; }
                  else if (idx == _quizSelected) { bg = const Color(0xFFE74C3C); fg = Colors.white; }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _answerQuiz(idx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: bg, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _quizAnswered && idx == _quizCorrectIndex ? const Color(0xFF27AE60) : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
                            child: Center(child: Text(String.fromCharCode(65 + idx), style: TextStyle(fontWeight: FontWeight.w800, color: fg))),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(opt, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg))),
                          if (_quizAnswered && idx == _quizCorrectIndex) const Icon(Icons.check_circle, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_quizAnswered) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => setState(() { _inQuiz = false; _quizAnswered = false; _quizSelected = null; }),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Continue Learning', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              if (!_quizAnswered) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _speak(question),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE67E22).withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.volume_up, size: 18, color: Color(0xFFE67E22)),
                        SizedBox(width: 6),
                        Text('Hear again', style: TextStyle(color: Color(0xFFE67E22), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('⭐ $_stars stars', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

Color _subjectColor(String name) {
  switch (name.toLowerCase()) {
    case 'english': return const Color(0xFF4A90D9);
    case 'chichewa': return const Color(0xFF27AE60);
    case 'mathematics': return const Color(0xFFE67E22);
    case 'science': return const Color(0xFF8E44AD);
    case 'social studies': return const Color(0xFFE74C3C);
    default: return const Color(0xFF4A90D9);
  }
}

IconData _subjectIcon(String name) {
  switch (name.toLowerCase()) {
    case 'english': return Icons.abc;
    case 'chichewa': return Icons.translate;
    case 'mathematics': return Icons.calculate;
    case 'science': return Icons.biotech;
    case 'social studies': return Icons.public;
    default: return Icons.book;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(onTap != null ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(onTap != null ? 0.3 : 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color.withOpacity(onTap != null ? 1.0 : 0.4), size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color.withOpacity(onTap != null ? 1.0 : 0.4))),
          ],
        ),
      ),
    );
  }
}
