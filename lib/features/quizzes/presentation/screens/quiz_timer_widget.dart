import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class QuizTimerWidget extends StatelessWidget {
  final int seconds;

  const QuizTimerWidget({super.key, required this.seconds});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? DesignTokens.warning.withValues(alpha: 0.15)
            : DesignTokens.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.timer, size: 16, color: DesignTokens.warning),
        const SizedBox(width: 4),
        Text(
          '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: DesignTokens.warning),
        ),
      ]),
    );
  }
}
