import 'package:flutter/material.dart';

Future<String?> showReaderAiActionSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Ask AI About This Section',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (final item in const [
                ('explain', 'Explain this section', Icons.lightbulb_outline),
                (
                  'explain_level',
                  'Explain at my level',
                  Icons.school_outlined
                ),
                ('summary', 'Summarize this section', Icons.summarize_outlined),
                (
                  'memory',
                  'Create a memory hook',
                  Icons.psychology_alt_outlined
                ),
                (
                  'quiz_page',
                  'Quiz me on this page',
                  Icons.quiz_outlined
                ),
                (
                  'flashcards_selection',
                  'Flashcards from this material',
                  Icons.style_outlined
                ),
                (
                  'translate_chichewa',
                  'Translate to Chichewa',
                  Icons.translate_outlined
                ),
              ])
                ListTile(
                  leading: Icon(item.$3),
                  title: Text(item.$2),
                  onTap: () => Navigator.of(context).pop(item.$1),
                ),
            ],
          ),
        ),
      );
    },
  );
}
