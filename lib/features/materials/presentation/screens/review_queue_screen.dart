import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  int _currentIndex = 0;
  bool _showAnswer = false;
  bool _submitting = false;
  List<Map<String, dynamic>>? _cards;
  int? _totalCount;

  void _flip() {
    setState(() => _showAnswer = !_showAnswer);
  }

  Future<void> _submitReview(String reviewId, int quality) async {
    setState(() => _submitting = true);
    try {
      final client = GraphQLProvider.of(context).value;
      await client.mutate(MutationOptions(
        document: gql(kSubmitFlashcardReview),
        variables: {'reviewId': reviewId, 'quality': quality},
      ));
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _showAnswer = false;
      if (_cards != null && _currentIndex < _cards!.length - 1) {
        _currentIndex++;
      } else {
        _cards = null;
        _currentIndex = 0;
      }
      _submitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Queue',
            style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          if (_cards != null && _totalCount != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${_currentIndex + 1} / ${_cards!.length}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
        ],
      ),
      body: Query(
        options: QueryOptions(
          document: gql(kDueFlashcardReviews),
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading && _cards == null) {
            return const Center(child: LoadingWidget());
          }

          if (result.hasException && _cards == null) {
            return ErrorState(
              message: graphQLErrorMessage(
                  result.exception, 'Could not load reviews.'),
              onRetry: () => refetch?.call(),
            );
          }

          _cards ??= ((result.data?['dueFlashcardReviews'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _totalCount = result.data?['dueReviewCount'] as int? ?? 0;

          if (_cards!.isEmpty) {
            return _buildEmptyState();
          }

          return _buildCardView();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
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
                style:
                    TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
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
              onPressed: () => context.push('/materials'),
              icon: const Icon(Icons.menu_book_rounded, size: 18),
              label: const Text('Browse Materials'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardView() {
    final card = _cards![_currentIndex];
    final frontText = card['frontText']?.toString() ?? '';
    final backText = card['backText']?.toString() ?? '';
    final materialTitle = card['materialTitle']?.toString() ?? '';
    final materialSlug = card['materialSlug']?.toString() ?? '';
    final reviewId = card['id']?.toString() ?? '';

    return Column(
      children: [
        // Material source chip
        if (materialTitle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: GestureDetector(
              onTap: () => context.push('/materials/$materialSlug'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: DesignTokens.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.menu_book_rounded,
                        size: 14, color: DesignTokens.primary),
                    const SizedBox(width: 6),
                    Text(materialTitle,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: DesignTokens.primary)),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        // Flashcard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _flip,
              child: AnimatedContainer(
                duration: 300.ms,
                curve: Curves.easeInOut,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _showAnswer
                      ? DesignTokens.success.withValues(alpha: 0.05)
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _showAnswer
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
                        duration: 200.ms,
                        child: _showAnswer
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
                      _showAnswer ? 'Tap to see question' : 'Tap to reveal answer',
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
        ),
        // Rating buttons
        if (_showAnswer) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Row(
              children: [
                Expanded(
                  child: _RatingButton(
                    label: 'Again',
                    emoji: '🔄',
                    color: DesignTokens.error,
                    onTap: _submitting
                        ? null
                        : () => _submitReview(reviewId, 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RatingButton(
                    label: 'Hard',
                    emoji: '🤔',
                    color: DesignTokens.warning,
                    onTap: _submitting
                        ? null
                        : () => _submitReview(reviewId, 1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RatingButton(
                    label: 'Good',
                    emoji: '👍',
                    color: DesignTokens.primary,
                    onTap: _submitting
                        ? null
                        : () => _submitReview(reviewId, 2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _RatingButton(
                    label: 'Easy',
                    emoji: '⚡',
                    color: DesignTokens.success,
                    onTap: _submitting
                        ? null
                        : () => _submitReview(reviewId, 3),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 100),
        ],
      ],
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback? onTap;

  const _RatingButton({
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
