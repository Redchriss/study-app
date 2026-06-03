import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardRecentPanel extends StatelessWidget {
  final List<Map<String, dynamic>> materials;
  const DashboardRecentPanel({super.key, required this.materials});

  Color _colorFor(Map<String, dynamic> m) {
    final name = (m['subject']?['name'] ?? '').toLowerCase();
    if (name.contains('math')) return DesignTokens.warning;
    if (name.contains('science') || name.contains('bio')) {
      return DesignTokens.success;
    }
    if (name.contains('english') || name.contains('chichewa')) {
      return DesignTokens.primary;
    }
    return DesignTokens.accent;
  }

  @override
  Widget build(BuildContext context) {
    if (materials.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              DesignTokens.spMd, 0, DesignTokens.spMd, DesignTokens.spSm),
          child: SectionHeader(
            title: 'Recent Materials',
            actionLabel: 'See all',
            onAction: () => context.push('/materials'),
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(
                DesignTokens.spMd, 0, DesignTokens.spMd, 0),
            itemCount: materials.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: DesignTokens.spSm),
            itemBuilder: (_, i) {
              final m = materials[i];
              final color = _colorFor(m);
              return AnimatedPress(
                onTap: () => context.push('/materials/${m['slug']}'),
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: (dark
                                ? DesignTokens.darkBorder
                                : DesignTokens.border)
                            .withValues(alpha: 0.5)),
                    boxShadow: DesignTokens.shadowSm(dark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.description_rounded,
                            color: color, size: 18),
                      ),
                      const Spacer(),
                      Text(m['title']?.toString() ?? '',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(m['subject']?['name']?.toString() ?? '',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: DesignTokens.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}
