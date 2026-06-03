import 'package:flutter/material.dart';

class KidsModeSuggestionDialog extends StatelessWidget {
  const KidsModeSuggestionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: const Row(
        children: [
          Text('🎮 ', style: TextStyle(fontSize: 28)),
          Text('Try Kids Mode?',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        ],
      ),
      content: const Text(
        'Yaza has a special learning mode for primary students — '
        'big buttons, fun stories, games, and a companion character that '
        'earns stars. A parent or guardian can set it up now.',
        style: TextStyle(fontSize: 14, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Maybe later'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Set up Kids Mode'),
        ),
      ],
    );
  }
}
