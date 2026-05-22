import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import 'scanner_results_solution_card.dart';
import 'scanner_results_summary_bar.dart';

class ScannerResultsScreen extends StatelessWidget {
  final Map<String, dynamic> sessionData;
  const ScannerResultsScreen({super.key, required this.sessionData});

  @override
  Widget build(BuildContext context) {
    final solutions = (sessionData['solutions'] as List?) ?? [];
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          dark ? DesignTokens.darkBackground : DesignTokens.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor:
                dark ? DesignTokens.darkSurface : DesignTokens.surface,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => context.pop()),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Solutions',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800)),
                    Text(
                        '${solutions.length} question${solutions.length == 1 ? '' : 's'} solved',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: DesignTokens.textSecondary)),
                  ]),
            ),
          ),
          if (solutions.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              color:
                                  DesignTokens.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.document_scanner_outlined,
                              size: 40, color: DesignTokens.primary)),
                      const SizedBox(height: 16),
                      Text('No solutions found',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Try scanning a clearer photo of your paper.',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: DesignTokens.textSecondary),
                          textAlign: TextAlign.center),
                    ]),
              ),
            )
          else ...[
            SliverToBoxAdapter(
                child:
                    ScannerResultsSummaryBar(solutions: solutions, dark: dark)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                  16, 8, 16, MediaQuery.of(context).padding.bottom + 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => ScannerResultsSolutionCard(
                    solution: solutions[i] as Map<String, dynamic>,
                    index: i,
                    dark: dark,
                  )
                      .animate(delay: (i * 60).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, end: 0),
                  childCount: solutions.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
