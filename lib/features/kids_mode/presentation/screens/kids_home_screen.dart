import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

const _standards = [1, 2, 3, 4, 5, 6, 7, 8];
const _subjects = [
  ('English', Icons.abc, Color(0xFF4A90D9)),
  ('Chichewa', Icons.translate, Color(0xFF27AE60)),
  ('Math', Icons.calculate, Color(0xFFE67E22)),
  ('Science', Icons.biotech, Color(0xFF8E44AD)),
  ('Social', Icons.public, Color(0xFFE74C3C)),
];

final _sampleLessons = {
  'English': [
    'The cat sat on the mat. It was a big fat cat.\nThe cat liked to nap in the sun.',
    'I can run and jump.\nI can play all day.\nRunning is fun for me.',
    'This is a ball.\nThe ball is red and round.\nI like to play with my ball.',
  ],
  'Chichewa': [
    'Kali ndi mphaka.\nAmakhala pansi.\nAmakonda kusewera.',
    'Mwana wanga amaphunzira.\nAmafuna kuwerenga.\ndziwe zambiri.',
    'Mbewu imamera.\nImakula ndi mvula.\nDziwani za chilengedwe.',
  ],
  'Math': [
    'One apple plus one apple makes two apples.\n1 + 1 = 2',
    'Count the stars: 1, 2, 3, 4, 5.\nFive stars in the sky.',
    'A circle is round.\nA square has four sides.\nA triangle has three sides.',
  ],
  'Science': [
    'The sun is hot and bright.\nIt gives us light in the day.\nPlants need sun to grow.',
    'Water is wet.\nWe drink water every day.\nFish live in water.',
    'Leaves are green.\nTrees are tall.\nFlowers smell nice.',
  ],
  'Social': [
    'Malawi is our country.\nThe flag has red, green, and black.\nWe live in peace.',
    'We help each other.\nA family loves and cares.\nSharing is good.',
    'Lake Malawi is big.\nFish swim in the lake.\nBoats float on water.',
  ],
};

Color _subjectColor(String subj) {
  for (final s in _subjects) {
    if (s.$1 == subj) return s.$3;
  }
  return Colors.blue;
}

IconData _subjectIcon(String subj) {
  for (final s in _subjects) {
    if (s.$1 == subj) return s.$2;
  }
  return Icons.book;
}

class KidsHomeScreen extends StatefulWidget {
  const KidsHomeScreen({super.key});
  @override
  State<KidsHomeScreen> createState() => _KidsHomeScreenState();
}

class _KidsHomeScreenState extends State<KidsHomeScreen> {
  final _tts = FlutterTts();
  int? _selectedStandard;
  String? _selectedSubject;
  String _lessonText = '';
  int _lessonIndex = 0;
  bool _isSpeaking = false;

  // Quiz state
  bool _inQuiz = false;
  String _quizQuestion = '';
  List<String> _quizOptions = [];
  int _quizCorrectIndex = 0;
  int? _quizSelected;
  bool _quizAnswered = false;
  int _score = 0;
  int _totalQuiz = 0;
  int _streak = 0;

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
    _tts.setCompletionHandler(null);
    super.dispose();
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    setState(() => _isSpeaking = true);
    await _tts.speak(text.replaceAll('\n', ' '));
  }

  void _pickStandard(int s) {
    setState(() {
      _selectedStandard = s;
      _selectedSubject = null;
      _inQuiz = false;
    });
  }

  void _pickSubject(String subj) {
    final lessons = _sampleLessons[subj]!;
    final idx = Random().nextInt(lessons.length);
    setState(() {
      _selectedSubject = subj;
      _lessonText = lessons[idx];
      _lessonIndex = idx;
      _inQuiz = false;
      _quizAnswered = false;
      _quizSelected = null;
    });
  }

  void _generateQuiz() {
    final r = Random();
    final correct = 'What is this lesson about?';
    final opts = <String>[
      _lessonText.split('\n')[0].trim(),
      'A different story',
      'Fun and games',
    ]..shuffle(r);
    final correctIdx = opts.indexOf(_lessonText.split('\n')[0].trim());
    setState(() {
      _quizQuestion = 'What did we just learn?';
      _quizOptions = opts;
      _quizCorrectIndex = correctIdx;
      _inQuiz = true;
      _quizAnswered = false;
      _quizSelected = null;
    });
    _speak(_quizQuestion);
  }

  void _answerQuiz(int idx) {
    if (_quizAnswered) return;
    final correct = idx == _quizCorrectIndex;
    setState(() {
      _quizSelected = idx;
      _quizAnswered = true;
      _totalQuiz++;
      if (correct) {
        _score++;
        _streak++;
      } else {
        _streak = 0;
      }
    });
    _speak(correct ? 'Correct! Well done!' : 'Try again next time!');
  }

  void _nextLesson() {
    final lessons = _sampleLessons[_selectedSubject]!;
    final idx = (_lessonIndex + 1) % lessons.length;
    setState(() {
      _lessonText = lessons[idx];
      _lessonIndex = idx;
      _inQuiz = false;
      _quizAnswered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _selectedSubject == null
            ? _buildPicker()
            : _buildLesson(),
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
              const Text('⭐ Yaza Kids', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              IconButton(
                icon: const Icon(Icons.star, color: Color(0xFFF1C40F), size: 32),
                onPressed: () {
                  _speak('You have $_score stars!');
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('⭐ Your Stars'),
                      content: Text('You earned $_score stars!\nBest streak: $_streak in a row!'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_selectedStandard == null) ...[
            const Text('What class are you in?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Pick your Standard',
                style: TextStyle(fontSize: 15, color: Colors.grey[600])),
            const SizedBox(height: 24),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: WrapAlignment.center,
              children: _standards.map((s) => GestureDetector(
                onTap: () => _pickStandard(s),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Color(0xFF4A90D9).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF4A90D9).withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$s', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Color(0xFF4A90D9))),
                      Text('Std $s', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
              )).toList(),
            ),
          ] else ...[
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _selectedStandard = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Color(0xFF4A90D9).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back, size: 18, color: Color(0xFF4A90D9)),
                        SizedBox(width: 4),
                        Text('Change', style: TextStyle(color: Color(0xFF4A90D9), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Text('Standard $_selectedStandard',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 28),
            const Text('Pick a subject',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            ...(_subjects.map((s) {
              final name = s.$1;
              final icon = s.$2;
              final color = s.$3;
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GestureDetector(
                  onTap: () => _pickSubject(name),
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
            })),
          ],
        ],
      ),
    );
  }

  Widget _buildLesson() {
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
                    color: _subjectColor(_selectedSubject!).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_subjectIcon(_selectedSubject!), size: 18, color: _subjectColor(_selectedSubject!)),
                      const SizedBox(width: 4),
                      Text('Back', style: TextStyle(color: _subjectColor(_selectedSubject!), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text('$_selectedSubject · Std $_selectedStandard',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 24),
          if (_inQuiz) ...[
            _buildQuizCard(),
          ] else ...[
            _buildLessonCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildLessonCard() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: _subjectColor(_selectedSubject!).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: _subjectColor(_selectedSubject!).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_subjectIcon(_selectedSubject!), size: 36, color: _subjectColor(_selectedSubject!)),
              ),
              const SizedBox(height: 24),
              Text(
                _lessonText,
                style: const TextStyle(fontSize: 24, height: 1.6, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    icon: _isSpeaking ? Icons.stop : Icons.volume_up,
                    label: _isSpeaking ? 'Stop' : 'Listen',
                    color: const Color(0xFF27AE60),
                    onTap: () {
                      if (_isSpeaking) {
                        _tts.stop();
                        setState(() => _isSpeaking = false);
                      } else {
                        _speak(_lessonText);
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  _ActionButton(
                    icon: Icons.quiz_outlined,
                    label: 'Quiz',
                    color: const Color(0xFFE67E22),
                    onTap: _generateQuiz,
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
              icon: Icons.arrow_forward,
              label: 'Next',
              color: const Color(0xFF4A90D9),
              onTap: _nextLesson,
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
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: const Color(0xFFE67E22).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.quiz, color: Color(0xFFE67E22), size: 28),
                  const SizedBox(width: 8),
                  Text('$_totalQuiz', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => _speak(_quizQuestion),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF9E7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(_quizQuestion,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.volume_up, color: Color(0xFFE67E22), size: 24),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ..._quizOptions.asMap().entries.map((e) {
                final idx = e.key;
                final opt = e.value;
                Color bg = const Color(0xFFF0F0F0);
                Color fg = Colors.black87;
                if (_quizAnswered) {
                  if (idx == _quizCorrectIndex) {
                    bg = const Color(0xFF27AE60);
                    fg = Colors.white;
                  } else if (idx == _quizSelected) {
                    bg = const Color(0xFFE74C3C);
                    fg = Colors.white;
                  }
                } else if (idx == _quizSelected) {
                  bg = const Color(0xFF4A90D9);
                  fg = Colors.white;
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => _answerQuiz(idx),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _quizAnswered && idx == _quizCorrectIndex
                            ? const Color(0xFF27AE60)
                            : Colors.transparent, width: 2),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: _quizAnswered && idx == _quizCorrectIndex
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + idx),
                                style: TextStyle(fontWeight: FontWeight.w800, color: fg),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: Text(opt, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: fg))),
                          if (_quizAnswered && idx == _quizCorrectIndex)
                            const Icon(Icons.check_circle, color: Colors.white, size: 28),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              if (_quizAnswered) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _inQuiz = false;
                      _quizAnswered = false;
                      _quizSelected = null;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Text('Continue Learning',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
              if (!_quizAnswered) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _speak(_quizQuestion),
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
        Text('⭐ $_score stars', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}
