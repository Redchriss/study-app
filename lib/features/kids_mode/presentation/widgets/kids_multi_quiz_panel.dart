import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../kids_visual_theme.dart';
import 'kids_quiz_question_panel.dart';
import 'kids_quiz_shared.dart';
import 'kids_quiz_summary_panel.dart';

class KidsMultiQuizPanel extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final void Function({required int correct, required int total}) onComplete;
  final VoidCallback onBack;

  const KidsMultiQuizPanel({
    super.key,
    required this.lesson,
    required this.onComplete,
    required this.onBack,
  });

  @override
  State<KidsMultiQuizPanel> createState() => _KidsMultiQuizPanelState();
}

class _KidsMultiQuizPanelState extends State<KidsMultiQuizPanel> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int? _selected;
  bool _answered = false;
  int _correct = 0;
  bool _done = false;
  late AnimationController _burstCtrl;

  @override
  void initState() {
    super.initState();
    _burstCtrl = AnimationController(vsync: this, duration: 700.ms);
    _parseQuestions();
  }

  @override
  void didUpdateWidget(KidsMultiQuizPanel old) {
    super.didUpdateWidget(old);
    if (old.lesson['id'] != widget.lesson['id']) {
      _parseQuestions();
      setState(() {
        _current = 0;
        _selected = null;
        _answered = false;
        _correct = 0;
        _done = false;
      });
    }
  }

  void _parseQuestions() {
    final raw = widget.lesson['quiz'];
    if (raw is List) {
      _questions = raw
          .map((q) {
            if (q is Map<String, dynamic>) return q;
            if (q is String) {
              try {
                final d = jsonDecode(q);
                if (d is Map<String, dynamic>) return d;
              } catch (_) {}
            }
            return <String, dynamic>{};
          })
          .where((q) => q.isNotEmpty)
          .toList();
    } else {
      _questions = [];
    }
  }

  @override
  void dispose() {
    _burstCtrl.dispose();
    super.dispose();
  }

  void _answer(int idx) {
    if (_answered) return;
    final q = _questions[_current];
    final correctIdx = (q['correct'] as num?)?.toInt() ?? 0;
    HapticFeedback.mediumImpact();
    setState(() {
      _selected = idx;
      _answered = true;
      if (idx == correctIdx) _correct++;
    });
    if (idx == correctIdx) _burstCtrl.forward(from: 0);
  }

  void _next() {
    if (_current + 1 >= _questions.length) {
      setState(() => _done = true);
      widget.onComplete(correct: _correct, total: _questions.length);
    } else {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined,
                  size: 48, color: KidsVisualTheme.pathBlue),
              const SizedBox(height: 12),
              const Text('No quiz questions yet for this lesson.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: KidsVisualTheme.ink)),
              const SizedBox(height: 16),
              KidsActionButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Back to lesson',
                  color: KidsVisualTheme.pathBlue,
                  onTap: widget.onBack),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms);
    }
    if (_done)
      return KidsQuizSummaryPanel(
          correct: _correct,
          total: _questions.length,
          onRetry: () => setState(() {
                _current = 0;
                _selected = null;
                _answered = false;
                _correct = 0;
                _done = false;
              }),
          onBack: widget.onBack);
    return KidsQuizQuestionPanel(
      question: _questions[_current],
      index: _current,
      total: _questions.length,
      selected: _selected,
      answered: _answered,
      onAnswer: _answer,
      onNext: _next,
      onBack: widget.onBack,
    );
  }
}
