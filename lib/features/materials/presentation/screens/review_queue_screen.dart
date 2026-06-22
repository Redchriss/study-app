import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/errors/app_exception.dart';
import 'review_queue_widgets.dart';

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
            return const ReviewEmptyState();
          }

          return _buildCardView();
        },
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
        ReviewFlashcardCard(
          frontText: frontText,
          backText: backText,
          showAnswer: _showAnswer,
          onFlip: _flip,
        ),
        // Rating buttons
        if (_showAnswer) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: Row(
              children: [
                Expanded(
                  child: FlashcardRatingButton(
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
                  child: FlashcardRatingButton(
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
                  child: FlashcardRatingButton(
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
                  child: FlashcardRatingButton(
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

