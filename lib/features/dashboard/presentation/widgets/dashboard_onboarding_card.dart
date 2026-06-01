import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardOnboardingCard extends StatelessWidget {
  const DashboardOnboardingCard({super.key});

  static const _subjects = [
    _SubjectSuggestion('Mathematics', Icons.calculate_rounded,
        DesignTokens.warning),
    _SubjectSuggestion('English', Icons.menu_book_rounded,
        DesignTokens.primary),
    _SubjectSuggestion('Science', Icons.biotech_rounded,
        DesignTokens.success),
    _SubjectSuggestion('History', Icons.history_rounded,
        DesignTokens.accent),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spMd),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [
                          Color(0xFF1B6CA8),
                          Color(0xFF7C4DFF)
                        ]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.auto_stories_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome to Yaza!',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      Text('Pick a subject to start learning',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(
                                  color: DesignTokens.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Recommended for you',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            ..._subjects.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AnimatedPress(
                  onTap: () =>
                      context.push('/materials'),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: s.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              s.color.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: s.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s.icon,
                              color: s.color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const Spacer(),
                        Icon(Icons.chevron_right_rounded,
                            color: DesignTokens.textTertiary,
                            size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/materials'),
                icon: const Icon(Icons.explore_outlined, size: 18),
                label: const Text('Browse all materials'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectSuggestion {
  final String name;
  final IconData icon;
  final Color color;
  const _SubjectSuggestion(this.name, this.icon, this.color);
}
