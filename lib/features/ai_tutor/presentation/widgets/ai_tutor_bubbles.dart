import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

String sanitizeStreamingMarkdown(String text) {
  final codeFences = '```'.allMatches(text).length;
  if (codeFences.isOdd) text += '\n```';
  final boldMarkers = '**'.allMatches(text).length;
  if (boldMarkers.isOdd) text += '**';
  final italicMarkers = RegExp(r'(?<!\*)\*(?!\*)').allMatches(text).length;
  if (italicMarkers.isOdd) text += ' _';
  final tableSep = RegExp(r'\|[-| ]+\|').allMatches(text).length;
  if (tableSep > 0 && !text.endsWith('|\n')) text += '\n';
  return text;
}

class AiUserBubble extends StatelessWidget {
  final String text;
  const AiUserBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.only(bottom: 10, left: 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          gradient:
              LinearGradient(colors: [Color(0xFF1B6CA8), Color(0xFF7C4DFF)]),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.5)),
      ),
    ).animate().fadeIn(duration: 200.ms).slideX(begin: 0.1);
  }
}
