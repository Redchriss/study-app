import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../kids_visual_theme.dart';
import 'kids_chunk_card.dart';
import 'kids_quiz_shared.dart';

Map<String, dynamic> _parseChunk(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return {'emoji': '\u{1F4D6}', 'text': raw?.toString() ?? ''};
}

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
      final body = widget.lesson['bodyText'] as String? ?? '';
      final lines = body.split('\n').where((l) => l.trim().isNotEmpty).toList();
      final emojis = [
        '\u{1F4D6}',
        '\u{1F50D}',
        '\u{1F4A1}',
        '\u{1F31F}',
        '\u{1F3AF}',
        '\u{2705}',
        '\u{1F9E0}',
        '\u{1F389}'
      ];
      _chunks = lines
          .asMap()
          .entries
          .map((e) =>
              {'emoji': emojis[e.key % emojis.length], 'text': e.value.trim()})
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.lesson['title'] as String? ?? 'Lesson';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: KidsVisualTheme.ink)),
        const SizedBox(height: 4),
        Text('${_chunks.length} ideas to explore',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: KidsVisualTheme.inkMuted)),
        const SizedBox(height: 16),
        ..._chunks.asMap().entries.map((entry) => KidsChunkCard(
              index: entry.key,
              emoji: entry.value['emoji'] as String? ?? '\u{1F4D6}',
              text: entry.value['text'] as String? ?? '',
              isSelected: widget.selectedChunk == entry.key,
              onTap: () => widget.onChunkTap(entry.key),
            )
                .animate(delay: (entry.key * 60).ms)
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.05, end: 0)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
                child: KidsActionButton(
              icon: widget.isSpeaking
                  ? Icons.stop_rounded
                  : Icons.volume_up_rounded,
              label: widget.isSpeaking ? 'Stop' : 'Listen',
              color: KidsVisualTheme.pathBlue,
              onTap: widget.onListenTap,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: KidsActionButton(
              icon: Icons.quiz_rounded,
              label: 'Quiz time!',
              color: const Color(0xFF9B59B6),
              onTap: widget.onStartQuiz,
            )),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
            width: double.infinity,
            child: KidsActionButton(
              icon: Icons.auto_awesome,
              label: 'Next lesson',
              color: KidsVisualTheme.trailGreen,
              onTap: widget.onNextLesson,
            )),
      ],
    );
  }
}
