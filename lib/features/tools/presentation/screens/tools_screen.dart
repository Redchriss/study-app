import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ToolsScreen extends ConsumerWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tools',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
      ),
      body: Query(
        options: QueryOptions(
          document: gql(kMe),
          fetchPolicy: FetchPolicy.cacheFirst,
        ),
        builder: (result, {fetchMore, refetch}) {
          final me = result.data?['me'] as Map<String, dynamic>?;
          final credits =
              (me?['profile']?['aiCredits'] as num?)?.toInt() ?? 0;

          return RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DesignTokens.spMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credit balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(DesignTokens.spMd),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)],
                      ),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusXl),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.bolt_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: DesignTokens.spMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('AI Credits',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontWeight: FontWeight.w600)),
                              Text('$credits credits',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.push('/upgrade'),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Get More'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: DesignTokens.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spXl),

                  // AI Tools section
                  Text('AI Tools',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: DesignTokens.spSm),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: DesignTokens.spSm,
                    crossAxisSpacing: DesignTokens.spSm,
                    childAspectRatio: 1.1,
                    children: [
                      _ToolCard(
                        label: 'Paper Solver',
                        icon: Icons.document_scanner_rounded,
                        color: const Color(0xFFFF6B35),
                        description: 'Solve past papers with AI',
                        cost: 1,
                        onTap: () => context.push('/scanner'),
                      ),
                      _ToolCard(
                        label: 'AI Tutor',
                        icon: Icons.psychology_rounded,
                        color: const Color(0xFF7C4DFF),
                        description: 'Chat with your study assistant',
                        cost: 0,
                        onTap: () => context.push('/ai-tutor'),
                      ),
                      _ToolCard(
                        label: 'Diagnostic',
                        icon: Icons.assessment_rounded,
                        color: const Color(0xFF2EC4B6),
                        description: 'Test your knowledge level',
                        cost: 0,
                        onTap: () =>
                            context.push('/diagnostic/MATH-S'),
                      ),
                      _ToolCard(
                        label: 'Knowledge Map',
                        icon: Icons.bubble_chart_rounded,
                        color: const Color(0xFF1B6CA8),
                        description: 'See your learning progress',
                        cost: 0,
                        onTap: () => context.push('/knowledge-map'),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spXl),

                  // Study Tools section
                  Text('Study Tools',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: DesignTokens.spSm),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: DesignTokens.spSm,
                    crossAxisSpacing: DesignTokens.spSm,
                    childAspectRatio: 1.1,
                    children: [
                      _ToolCard(
                        label: 'Review Queue',
                        icon: Icons.replay_rounded,
                        color: const Color(0xFFF4A261),
                        description: 'Flashcards due for review',
                        cost: 0,
                        onTap: () => context.push('/review-queue'),
                      ),
                      _ToolCard(
                        label: 'Past Papers',
                        icon: Icons.library_books_rounded,
                        color: const Color(0xFFE76F51),
                        description: 'Browse exam papers',
                        cost: 0,
                        onTap: () => context.push('/past-papers'),
                      ),
                      _ToolCard(
                        label: 'Bookmarks',
                        icon: Icons.bookmark_rounded,
                        color: const Color(0xFF264653),
                        description: 'Your saved materials',
                        cost: 0,
                        onTap: () => context.push('/bookmarks'),
                      ),
                      _ToolCard(
                        label: 'History',
                        icon: Icons.history_rounded,
                        color: const Color(0xFF6A4C93),
                        description: 'Your study activity',
                        cost: 0,
                        onTap: () => context.push('/history'),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spXl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final String description;
  final int cost;
  final VoidCallback onTap;

  const _ToolCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.description,
    required this.cost,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPress(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(DesignTokens.spMd),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : DesignTokens.surface,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
              color: (dark ? DesignTokens.darkBorder : DesignTokens.border)
                  .withValues(alpha: 0.5)),
          boxShadow: DesignTokens.shadowSm(dark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(description,
                style: const TextStyle(
                    fontSize: 12, color: DesignTokens.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (cost > 0) ...[
              const SizedBox(height: 4),
              Text('$cost 💎',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }
}
