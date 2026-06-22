import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class FlashcardRatingButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback? onTap;

  const FlashcardRatingButton({
    super.key,
    required this.label,
    required this.emoji,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class ReviewFlashcardCard extends StatelessWidget {
  final String frontText;
  final String backText;
  final bool showAnswer;
  final VoidCallback onFlip;

  const ReviewFlashcardCard({
    super.key,
    required this.frontText,
    required this.backText,
    required this.showAnswer,
    required this.onFlip,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: GestureDetector(
          onTap: onFlip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            decoration: BoxDecoration(
              color: showAnswer
                  ? DesignTokens.success.withValues(alpha: 0.05)
                  : Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: showAnswer
                    ? DesignTokens.success.withValues(alpha: 0.2)
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: showAnswer
                        ? Column(
                            key: const ValueKey('answer'),
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DesignTokens.success
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('ANSWER',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: DesignTokens.success)),
                              ),
                              const SizedBox(height: 16),
                              Text(backText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 18, height: 1.6)),
                            ],
                          )
                        : Column(
                            key: const ValueKey('question'),
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: DesignTokens.primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('QUESTION',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: DesignTokens.primary)),
                              ),
                              const SizedBox(height: 16),
                              Text(frontText,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      height: 1.6)),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  showAnswer ? 'Tap to see question' : 'Tap to reveal answer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReviewEmptyState extends StatelessWidget {
  const ReviewEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: DesignTokens.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 44, color: DesignTokens.success),
            ),
            const SizedBox(height: 24),
            const Text('All caught up!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(
              'No flashcards due for review. Generate flashcards from your study materials to start reviewing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pushNamed('/materials'),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Browse Materials'),
            ),
          ],
        ),
      ),
    );
  }
}
