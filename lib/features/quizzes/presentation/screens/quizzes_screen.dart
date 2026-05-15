import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

// Subject → color mapping (same palette as materials screen)
const _subjectColors = {
  'mathematics': Color(0xFF1B6CA8),
  'maths': Color(0xFF1B6CA8),
  'biology': Color(0xFF27AE60),
  'physics': Color(0xFF7A4D9E),
  'chemistry': Color(0xFFE67E22),
  'history': Color(0xFF8B5E3C),
  'geography': Color(0xFF1F8A70),
  'english': Color(0xFFC0392B),
  'agriculture': Color(0xFF2ECC71),
  'computer': Color(0xFF2C3E50),
  'commerce': Color(0xFFF39C12),
  'life skills': Color(0xFFE91E63),
};

Color _colorFor(String? subject) {
  if (subject == null) return DesignTokens.primary;
  final key = subject.toLowerCase();
  for (final entry in _subjectColors.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return DesignTokens.primary;
}

class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: Query(
        options: QueryOptions(document: gql(kQuizzes), variables: const {'limit': 50}),
        builder: (result, {fetchMore, refetch}) {
          final quizzes = (result.data?['quizzes'] as List?) ?? [];

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 100,
                backgroundColor: dark ? DesignTokens.darkSurface : DesignTokens.surface,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  title: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quizzes',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (quizzes.isNotEmpty)
                        Text(
                          '${quizzes.length} available',
                          style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textSecondary),
                        ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => refetch?.call(),
                    tooltip: 'Refresh',
                  ),
                ],
              ),

              // Loading shimmer
              if (result.isLoading && quizzes.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, __) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: ShimmerBox(height: 96, radius: DesignTokens.radiusXl),
                      ),
                      childCount: 8,
                    ),
                  ),
                )

              // Error
              else if (result.hasException && quizzes.isEmpty)
                SliverFillRemaining(
                  child: ErrorState(
                    message: 'Could not load quizzes. Check your connection.',
                    onRetry: () => refetch?.call(),
                  ),
                )

              // Empty
              else if (quizzes.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            color: DesignTokens.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.quiz_outlined, size: 40, color: DesignTokens.primary),
                        ),
                        const SizedBox(height: 16),
                        Text('No quizzes yet', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          'Check back soon — quizzes are added regularly.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )

              // Quiz list
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final q = quizzes[i] as Map<String, dynamic>;
                        return _QuizCard(quiz: q, dark: dark, index: i);
                      },
                      childCount: quizzes.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Quiz card ────────────────────────────────────────────────────────────────
class _QuizCard extends StatelessWidget {
  final Map<String, dynamic> quiz;
  final bool dark;
  final int index;

  const _QuizCard({required this.quiz, required this.dark, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectName = quiz['subject']?['name'] as String? ?? '';
    final color = _colorFor(subjectName);
    final difficulty = quiz['difficulty'] as String? ?? 'medium';
    final questionCount = quiz['questionCount'] ?? 0;
    final durationMin = quiz['durationMinutes'];

    final diffColor = difficulty == 'easy'
        ? DesignTokens.success
        : difficulty == 'hard'
            ? DesignTokens.error
            : DesignTokens.warning;

    final diffLabel = difficulty[0].toUpperCase() + difficulty.substring(1);

    return AnimatedPress(
      onTap: () => context.go('/quiz/${quiz['slug']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          border: Border.all(
            color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.6),
          ),
          boxShadow: DesignTokens.shadowSm(dark),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left colour bar
              Container(
                width: 5,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(DesignTokens.radiusXl),
                    bottomLeft: Radius.circular(DesignTokens.radiusXl),
                  ),
                ),
              ),
              // Icon
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                child: Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Icon(Icons.quiz_outlined, color: color, size: 22),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 14, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        quiz['title'] as String? ?? '',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          // Subject chip
                          if (subjectName.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                subjectName,
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          // Difficulty badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: diffColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              diffLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: diffColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.help_outline_rounded, size: 12, color: DesignTokens.textTertiary),
                          const SizedBox(width: 4),
                          Text(
                            '$questionCount question${questionCount == 1 ? '' : 's'}',
                            style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary),
                          ),
                          if (durationMin != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.timer_outlined, size: 12, color: DesignTokens.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              '$durationMin min',
                              style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Center(
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: DesignTokens.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (index * 45).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.06, end: 0);
  }
}
