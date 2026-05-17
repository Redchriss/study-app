import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';

class AiTutorEmptyState extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String> onSuggestion;

  const AiTutorEmptyState({super.key, required this.suggestions, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [const Color(0xFF7C4DFF).withValues(alpha: 0.15), const Color(0xFF1B6CA8).withValues(alpha: 0.15)]),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome_rounded, size: 38, color: Color(0xFF7C4DFF)),
            ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 20),
            const Text('What do you want to learn?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800), textAlign: TextAlign.center)
                .animate(delay: 100.ms).fadeIn().slideY(begin: 0.2),
            const SizedBox(height: 8),
            const Text('Tap a suggestion or type your own question.', style: TextStyle(color: DesignTokens.textSecondary, fontSize: 13), textAlign: TextAlign.center)
                .animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
              children: suggestions.map((s) => ActionChip(
                label: Text(s),
                onPressed: () => onSuggestion(s),
                avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
              ).animate(delay: 300.ms).fadeIn().scale(begin: const Offset(0.9, 0.9))).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
