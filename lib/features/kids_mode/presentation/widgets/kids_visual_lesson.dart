import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../kids_visual_theme.dart';

/// Parses a JSON string that may be a Map or a raw string.
Map<String, dynamic> _parseChunk(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return {'emoji': '📖', 'text': raw?.toString() ?? ''};
}

Map<String, dynamic> _parseQuiz(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return {};
}

// ─── Illustrated lesson panel ─────────────────────────────────────────────────
/// Displays the AI-generated lesson as visual illustrated chunk cards.
/// Each chunk has an emoji + one friendly sentence.
class KidsVisualLessonPanel extends StatefulWidget {
  final Map<String, dynamic> lesson;
  final bool isSpeaking;
  final int selectedChunk;
  final VoidCallback onStartQuiz;
  final void Function(int) onChunkTap;
  final VoidCallback onListenTap;
  final VoidCallback onNextLesson;

  const KidsVisualLessonPanel({
    super.key,
    required this.lesson,
    required this.isSpeaking,
    required this.selectedChunk,
    required this.onStartQuiz,
    required this.onChunkTap,
    required this.onListenTap,
    required this.onNextLesson,
  });

  @override
  State<KidsVisualLessonPanel> createState() => _KidsVisualLessonPanelState();
}

class _KidsVisualLessonPanelState extends State<KidsVisualLessonPanel> {
  List<Map<String, dynamic>> _chunks = [];

  @override
  void initState() {
    super.initState();
    _parseChunks();
  }

  @override
  void didUpdateWidget(KidsVisualLessonPanel old) {
    super.didUpdateWidget(old);
    if (old.lesson['id'] != widget.lesson['id']) _parseChunks();
  }

  void _parseChunks() {
    final raw = widget.lesson['chunks'];
    List? rawList;
    if (raw is List) {
      rawList = raw;
    } else if (raw is String && raw.trim().startsWith('[')) {
      try {
        rawList = jsonDecode(raw) as List?;
      } catch (_) {}
    }
    
    if (rawList != null && rawList.isNotEmpty) {
      _chunks = rawList.map(_parseChunk).toList();
    } else {
      // Fallback: split bodyText into chunks
      final body = widget.lesson['bodyText'] as String? ?? '';
      final lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final emojis = ['📖', '🔍', '💡', '🌟', '🎯', '✅', '🧠', '🎉'];
      _chunks = lines.asMap().entries.map((e) {
        return {'emoji': emojis[e.key % emojis.length], 'text': e.value.trim()};
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lesson['title'] as String? ?? 'Lesson';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lesson title
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: KidsVisualTheme.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${_chunks.length} ideas to explore',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: KidsVisualTheme.inkMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Chunk cards
        ..._chunks.asMap().entries.map((entry) {
          final i = entry.key;
          final chunk = entry.value;
          final isSelected = widget.selectedChunk == i;
          return _ChunkCard(
            index: i,
            emoji: chunk['emoji'] as String? ?? '📖',
            text: chunk['text'] as String? ?? '',
            isSelected: isSelected,
            onTap: () => widget.onChunkTap(i),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
        }),

        const SizedBox(height: 20),

        // Action row
        Row(
          children: [
            Expanded(
              child: _KidsActionButton(
                icon: widget.isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                label: widget.isSpeaking ? 'Stop' : 'Listen',
                color: KidsVisualTheme.pathBlue,
                onTap: widget.onListenTap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KidsActionButton(
                icon: Icons.quiz_rounded,
                label: 'Quiz time!',
                color: const Color(0xFF9B59B6),
                onTap: widget.onStartQuiz,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: _KidsActionButton(
            icon: Icons.auto_awesome,
            label: 'Next lesson',
            color: KidsVisualTheme.trailGreen,
            onTap: widget.onNextLesson,
          ),
        ),
      ],
    );
  }
}

class _ChunkCard extends StatelessWidget {
  final int index;
  final String emoji;
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChunkCard({
    required this.index,
    required this.emoji,
    required this.text,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: DesignTokens.durFast,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? KidsVisualTheme.pathBlue.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? KidsVisualTheme.pathBlue : Colors.white.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? KidsVisualTheme.chunkyShadow(KidsVisualTheme.pathBlue.withValues(alpha: 0.3), dy: 2)
              : [],
        ),
        child: Row(
          children: [
            // Emoji in a rounded box
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? KidsVisualTheme.ink : KidsVisualTheme.ink.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
            ),
            if (isSelected)
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: KidsVisualTheme.pathBlue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Multi-question quiz carousel ─────────────────────────────────────────────
/// Shows all quiz questions one at a time with a progress bar.
/// Tracks per-question answers, shows explanation, then a summary screen.
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

class _KidsMultiQuizPanelState extends State<KidsMultiQuizPanel>
    with SingleTickerProviderStateMixin {
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
      _questions = raw.map(_parseQuiz).where((q) => q.isNotEmpty).toList();
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
    final isCorrect = idx == correctIdx;
    HapticFeedback.mediumImpact();
    setState(() {
      _selected = idx;
      _answered = true;
      if (isCorrect) _correct++;
    });
    if (isCorrect) {
      _burstCtrl.forward(from: 0);
    }
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
              const Icon(Icons.quiz_outlined, size: 48, color: KidsVisualTheme.pathBlue),
              const SizedBox(height: 12),
              const Text(
                'No quiz questions yet for this lesson.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w700, color: KidsVisualTheme.ink),
              ),
              const SizedBox(height: 16),
              _KidsActionButton(
                icon: Icons.arrow_back_rounded,
                label: 'Back to lesson',
                color: KidsVisualTheme.pathBlue,
                onTap: widget.onBack,
              ),
            ],
          ),
        ),
      );
    }

    if (_done) return _buildSummary();

    return _buildQuestion();
  }

  Widget _buildQuestion() {
    final q = _questions[_current];
    final correctIdx = (q['correct'] as num?)?.toInt() ?? 0;
    final options = (q['options'] as List?)?.map((o) => o.toString()).toList() ?? [];
    final explanation = q['explanation'] as String? ?? '';
    final progress = (_current + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar + counter
        Row(
          children: [
            Text(
              'Q${_current + 1} of ${_questions.length}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: KidsVisualTheme.inkMuted,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.5),
                  valueColor: const AlwaysStoppedAnimation(KidsVisualTheme.trailGreen),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Question bubble
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: KidsVisualTheme.sunGold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KidsVisualTheme.sunGold.withValues(alpha: 0.4)),
          ),
          child: Text(
            q['question'] as String? ?? '',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: KidsVisualTheme.ink,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Options
        ...options.asMap().entries.map((e) {
          final idx = e.key;
          final opt = e.value;
          final isCorrect = idx == correctIdx;
          final isSelected = _selected == idx;

          Color bg = Colors.white;
          Color fg = KidsVisualTheme.ink;
          Color border = KidsVisualTheme.ink.withValues(alpha: 0.08);
          IconData? trailingIcon;

          if (_answered) {
            if (isCorrect) {
              bg = DesignTokens.success;
              fg = Colors.white;
              border = DesignTokens.success;
              trailingIcon = Icons.check_circle_rounded;
            } else if (isSelected) {
              bg = DesignTokens.error;
              fg = Colors.white;
              border = DesignTokens.error;
              trailingIcon = Icons.cancel_rounded;
            } else {
              bg = Colors.white.withValues(alpha: 0.6);
              fg = KidsVisualTheme.inkMuted;
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GestureDetector(
              onTap: _answered ? null : () => _answer(idx),
              child: AnimatedContainer(
                duration: DesignTokens.durFast,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: fg.withValues(alpha: _answered && isCorrect ? 0.25 : 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + idx),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: fg,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                    if (trailingIcon != null)
                      Icon(trailingIcon, color: fg, size: 22),
                  ],
                ),
              ),
            ),
          );
        }),

        // Explanation + next button when answered
        if (_answered) ...[
          if (explanation.isNotEmpty)
            AnimatedContainer(
              duration: DesignTokens.durNormal,
              margin: const EdgeInsets.only(top: 4, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DesignTokens.success.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: DesignTokens.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      explanation,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KidsVisualTheme.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          _KidsActionButton(
            icon: _current + 1 < _questions.length
                ? Icons.arrow_forward_rounded
                : Icons.emoji_events_rounded,
            label: _current + 1 < _questions.length ? 'Next question' : 'See results!',
            color: KidsVisualTheme.trailGreen,
            onTap: _next,
          ).animate().fadeIn(duration: 250.ms),
        ],

        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded, size: 16),
          label: const Text('Back to lesson'),
          style: TextButton.styleFrom(foregroundColor: KidsVisualTheme.inkMuted),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final total = _questions.length;
    final pct = total > 0 ? (_correct / total * 100).round() : 0;
    final emoji = pct >= 80 ? '🏆' : pct >= 60 ? '⭐' : '💪';
    final message = pct >= 80
        ? 'Brilliant! You are a star!'
        : pct >= 60
            ? 'Great effort! Keep going!'
            : 'Good try! Review the lesson and try again.';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 72)),
        const SizedBox(height: 12),
        Text(
          message,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: KidsVisualTheme.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryPill(label: '$_correct', sub: 'Correct', color: DesignTokens.success),
              const SizedBox(width: 16),
              _SummaryPill(label: '${total - _correct}', sub: 'Missed', color: DesignTokens.error),
              const SizedBox(width: 16),
              _SummaryPill(label: '$pct%', sub: 'Score', color: KidsVisualTheme.pathBlue),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _KidsActionButton(
          icon: Icons.replay_rounded,
          label: 'Try again',
          color: const Color(0xFF9B59B6),
          onTap: () {
            setState(() {
              _current = 0;
              _selected = null;
              _answered = false;
              _correct = 0;
              _done = false;
            });
          },
        ),
        const SizedBox(height: 10),
        _KidsActionButton(
          icon: Icons.arrow_back_rounded,
          label: 'Back to lesson',
          color: KidsVisualTheme.pathBlue,
          onTap: widget.onBack,
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

class _SummaryPill extends StatelessWidget {
  final String label, sub;
  final Color color;
  const _SummaryPill({required this.label, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color),
        ),
        Text(
          sub,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

// ─── Shared kids action button ─────────────────────────────────────────────────
class _KidsActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _KidsActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? color.withValues(alpha: 0.35) : color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap == null ? null : () {
          HapticFeedback.lightImpact();
          onTap!();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
