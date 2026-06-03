import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';

class KidsLessonEmptyState extends StatelessWidget {
  const KidsLessonEmptyState({super.key, required this.onRetryFetchLesson});

  final VoidCallback onRetryFetchLesson;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'No lesson available',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(
                  'No lesson available for this topic yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Ask AI to generate a lesson',
                child: FilledButton.icon(
                  onPressed: onRetryFetchLesson,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Ask AI to generate'),
                  style: FilledButton.styleFrom(
                      backgroundColor: KidsVisualTheme.pathBlue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
