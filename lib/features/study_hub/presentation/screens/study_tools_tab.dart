import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/design_tokens.dart';

class StudyToolsTab extends StatelessWidget {
  final bool dark;
  const StudyToolsTab({super.key, required this.dark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        _SectionHeader(title: 'Study Tools', subtitle: 'Everything you need to excel'),
        const SizedBox(height: 16),
        _ToolCard(
          icon: Icons.document_scanner_rounded,
          color: const Color(0xFFFFB300),
          title: 'AI Paper Solver',
          subtitle: 'Snap a past paper — AI solves it step by step',
          badge: 'AI • 1 credit',
          onTap: () => context.push('/scanner'),
          index: 0,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.history_rounded,
          color: DesignTokens.info,
          title: 'Study History',
          subtitle: 'Review your quiz attempts and study sessions',
          onTap: () => context.push('/history'),
          index: 1,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.emoji_events_rounded,
          color: DesignTokens.warning,
          title: 'Leaderboard',
          subtitle: 'See top learners and contributors',
          onTap: () => context.push('/leaderboard'),
          index: 2,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.bookmark_rounded,
          color: DesignTokens.secondary,
          title: 'Bookmarks',
          subtitle: 'Materials you saved for later',
          onTap: () => context.push('/bookmarks'),
          index: 3,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.library_books_rounded,
          color: DesignTokens.primary,
          title: 'Past Papers Library',
          subtitle: 'Browse and download past exam papers',
          onTap: () => context.push('/paper-library'),
          index: 4,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.upload_file_rounded,
          color: DesignTokens.accent,
          title: 'My Uploads',
          subtitle: 'Manage materials you have uploaded',
          onTap: () => context.push('/my-uploads'),
          index: 5,
        ),
        const SizedBox(height: 12),
        _ToolCard(
          icon: Icons.child_care_rounded,
          color: const Color(0xFFE87E5E),
          title: 'Kids Mode',
          subtitle: 'Learning for primary school children with games and stories',
          onTap: () => context.push('/kids'),
          index: 6,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  final int index;
  const _ToolCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
              color: dark
                  ? DesignTokens.darkBorder
                  : DesignTokens.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15)),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(badge!,
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: color)),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12, color: DesignTokens.textSecondary)),
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: DesignTokens.textTertiary),
          ],
        ),
      ),
    ).animate().fadeIn(
          delay: (50 * index).ms,
          duration: 300.ms,
          curve: Curves.easeOut,
        ).slideX(begin: 0.05);
  }
}
