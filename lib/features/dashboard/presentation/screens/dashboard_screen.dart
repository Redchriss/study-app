import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import '../../../../core/graphql/queries/queries.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Query(
      options: QueryOptions(document: gql(kDashboard)),
      builder: (result, {fetchMore, refetch}) {
        final me = result.data?['me'];
        final profile = me?['profile'];
        final recentMaterials = (result.data?['recentMaterials'] as List?) ?? [];
      
        final snap = result.data?['progressSnapshot'];
        final circles = (result.data?['myCircles'] as List?) ?? [];
        final name = me?['username'] as String? ?? 'Student';

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async => refetch?.call(),
            child: CustomScrollView(
              slivers: [
                // ── App Bar ──────────────────────────────────────────
                SliverAppBar(
                  floating: true,
                  title: Text('Yaza', style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  )),
                  actions: [
                    IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.go('/notifications'),
                    ),
                  ],
                ),

                // ── Hero Greeting ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spLg,
                    ),
                    child: GlassCard(
                      opacity: 0.7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $name 👋',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spXs),
                          Text(
                            profile?['educationLevel'] != null
                                ? 'Keep studying! You\'re doing great.'
                                : 'Set up your profile to get started.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: DesignTokens.textSecondary,
                            ),
                          ),
                          if (profile != null) ...[
                            const SizedBox(height: DesignTokens.spMd),
                            Row(
                              children: [
                                _StatChip(
                                  icon: Icons.local_fire_department,
                                  label: '${profile['studyStreak'] ?? 0} day streak',
                                  color: DesignTokens.secondary,
                                ),
                                const SizedBox(width: DesignTokens.spSm),
                                _StatChip(
                                  icon: Icons.star,
                                  label: '${profile['studyPoints'] ?? 0} pts',
                                  color: DesignTokens.warning,
                                ),
                                const SizedBox(width: DesignTokens.spSm),
                                _StatChip(
                                  icon: Icons.bolt,
                                  label: '${profile['aiCredits'] ?? 0} credits',
                                  color: DesignTokens.accent,
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Bento Grid ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spMd),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeader(
                          title: 'Quick Actions',
                          actionLabel: 'See all',
                          onAction: () {},
                        ),
                        const SizedBox(height: DesignTokens.spSm),
                        BentoGrid(
                          spacing: DesignTokens.spSm,
                          children: [
                            BentoCard(
                              columnSpan: 3,
                              onTap: () => context.go('/scanner'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.accent.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                    ),
                                    child: const Icon(Icons.document_scanner, color: DesignTokens.accent, size: 24),
                                  ),
                                  const SizedBox(height: DesignTokens.spXs),
                                  Text('Solve Paper', style: theme.textTheme.labelLarge),
                                ],
                              ),
                            ),
                            BentoCard(
                              columnSpan: 3,
                              onTap: () => context.go('/materials'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primaryLight.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                    ),
                                    child: const Icon(Icons.menu_book, color: DesignTokens.primaryLight, size: 24),
                                  ),
                                  const SizedBox(height: DesignTokens.spXs),
                                  Text('Materials', style: theme.textTheme.labelLarge),
                                ],
                              ),
                            ),
                            BentoCard(
                              columnSpan: 3,
                              onTap: () => context.go('/quizzes'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.secondary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                    ),
                                    child: const Icon(Icons.quiz_outlined, color: DesignTokens.secondary, size: 24),
                                  ),
                                  const SizedBox(height: DesignTokens.spXs),
                                  Text('Quizzes', style: theme.textTheme.labelLarge),
                                ],
                              ),
                            ),
                            BentoCard(
                              columnSpan: 3,
                              onTap: () => context.go('/ai-tutor'),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.info.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                    ),
                                    child: const Icon(Icons.auto_awesome, color: DesignTokens.info, size: 24),
                                  ),
                                  const SizedBox(height: DesignTokens.spXs),
                                  Text('AI Tutor', style: theme.textTheme.labelLarge),
                                ],
                              ),
                            ),
                            BentoCard(
                              columnSpan: 6,
                              onTap: () => context.go('/circles'),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48, height: 48,
                                    decoration: BoxDecoration(
                                      color: DesignTokens.primary.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                    ),
                                    child: const Icon(Icons.groups, color: DesignTokens.primary, size: 24),
                                  ),
                                  const SizedBox(width: DesignTokens.spMd),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Study Circles', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                                        Text('${circles.length} joined', style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: DesignTokens.textTertiary),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Progress Snapshot ─────────────────────────────────
                if (snap?['hasData'] == true)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionHeader(title: 'Your Progress'),
                          const SizedBox(height: DesignTokens.spSm),
                          GlassCard(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _ProgressStat(
                                      value: '${snap?['masteryPercent'] ?? 0}%',
                                      label: 'Mastery',
                                      color: DesignTokens.success,
                                    ),
                                    _ProgressStat(
                                      value: '${snap?['avgQuizScore'] ?? 0}%',
                                      label: 'Avg Score',
                                      color: DesignTokens.primary,
                                    ),
                                    _ProgressStat(
                                      value: '${snap?['questionsPracticed'] ?? 0}',
                                      label: 'Questions',
                                      color: DesignTokens.secondary,
                                    ),
                                  ],
                                ),
                                if ((snap?['weakestTopics'] as List?)?.isNotEmpty == true) ...[
                                  const Divider(height: DesignTokens.spXl),
                                  Row(
                                    children: [
                                      const Icon(Icons.trending_up, size: 16, color: DesignTokens.warning),
                                      const SizedBox(width: DesignTokens.spXs),
                                      Text('Focus on: ', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                      Expanded(
                                        child: Text(
                                          (snap?['weakestTopics'] as List).take(2).join(', '),
                                          style: theme.textTheme.bodyMedium?.copyWith(color: DesignTokens.textSecondary),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Recent Materials ──────────────────────────────────
                if (recentMaterials.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Recent Materials',
                            actionLabel: 'See all',
                            onAction: () => context.go('/materials'),
                          ),
                          const SizedBox(height: DesignTokens.spSm),
                          SizedBox(
                            height: 140,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: recentMaterials.length,
                              separatorBuilder: (_, __) => const SizedBox(width: DesignTokens.spSm),
                              itemBuilder: (_, i) {
                                final m = recentMaterials[i];
                                return AnimatedPress(
                                  onTap: () => context.go('/materials/${m['slug']}'),
                                  child: Container(
                                    width: 180,
                                    padding: const EdgeInsets.all(DesignTokens.spMd),
                                    decoration: BoxDecoration(
                                      color: theme.cardTheme.color,
                                      borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
                                      border: Border.all(color: (dark ? DesignTokens.darkBorder : DesignTokens.border).withValues(alpha: 0.5)),
                                      boxShadow: DesignTokens.shadowSm(dark),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          Container(
                                            width: 32, height: 32,
                                            decoration: BoxDecoration(
                                              color: DesignTokens.primary.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                                            ),
                                            child: const Icon(Icons.description, size: 16, color: DesignTokens.primary),
                                          ),
                                        ]),
                                        const Spacer(),
                                        Text(m['title'] ?? '', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        const SizedBox(height: DesignTokens.spXxs),
                                        Text(m['subject']?['name'] ?? '', style: theme.textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary)),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // ── Bottom Padding ─────────────────────────────────────
                const SliverToBoxAdapter(
                  child: SizedBox(height: DesignTokens.spXxl * 2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _StatChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spSm, vertical: DesignTokens.spXs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: DesignTokens.spXxs),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _ProgressStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _ProgressStat({required this.value, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: color,
      )),
      Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: DesignTokens.textTertiary)),
    ]);
  }
}
