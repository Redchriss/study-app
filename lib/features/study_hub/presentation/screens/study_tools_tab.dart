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
        Text('Study Tools',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('Everything you need to excel',
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6))),
        const SizedBox(height: 20),
        _AiTutorHero(dark: dark),
        const SizedBox(height: 20),
        Text('Tools & Resources',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _ToolGridCard(
              icon: Icons.document_scanner_rounded,
              color: const Color(0xFFFFB300),
              title: 'Paper Solver',
              subtitle: 'AI solves step by step',
              badge: '1 credit',
              onTap: () => context.push('/scanner'),
              index: 0,
            ),
            _ToolGridCard(
              icon: Icons.history_rounded,
              color: DesignTokens.info,
              title: 'History',
              subtitle: 'Past quiz attempts',
              onTap: () => context.push('/history'),
              index: 1,
            ),
            _ToolGridCard(
              icon: Icons.emoji_events_rounded,
              color: DesignTokens.warning,
              title: 'Leaderboard',
              subtitle: 'Top learners',
              onTap: () => context.push('/leaderboard'),
              index: 2,
            ),
            _ToolGridCard(
              icon: Icons.replay_rounded,
              color: const Color(0xFFFF6B00),
              title: 'Review Queue',
              subtitle: 'Spaced repetition',
              badge: 'SM-2',
              onTap: () => context.push('/review-queue'),
              index: 3,
            ),
            _ToolGridCard(
              icon: Icons.bookmark_rounded,
              color: DesignTokens.secondary,
              title: 'Bookmarks',
              subtitle: 'Saved materials',
              onTap: () => context.push('/bookmarks'),
              index: 4,
            ),
            _ToolGridCard(
              icon: Icons.library_books_rounded,
              color: DesignTokens.primary,
              title: 'Past Papers',
              subtitle: 'Exam papers library',
              onTap: () => context.push('/paper-library'),
              index: 5,
            ),
            _ToolGridCard(
              icon: Icons.upload_file_rounded,
              color: DesignTokens.accent,
              title: 'My Uploads',
              subtitle: 'Your materials',
              onTap: () => context.push('/my-uploads'),
              index: 6,
            ),
            _ToolGridCard(
              icon: Icons.child_care_rounded,
              color: const Color(0xFFE87E5E),
              title: 'Kids Mode',
              subtitle: 'Primary learning',
              onTap: () => context.push('/kids'),
              index: 7,
            ),
          ],
        ),
      ],
    );
  }
}

class _AiTutorHero extends StatelessWidget {
  final bool dark;
  const _AiTutorHero({required this.dark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/ai-tutor'),
      borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: DesignTokens.brandGradient,
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Tutor',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Ask anything, get step-by-step help',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut).slideY(
          begin: 0.06,
        );
  }
}

class _ToolGridCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback onTap;
  final int index;

  const _ToolGridCard({
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? DesignTokens.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          border: Border.all(
              color: dark
                  ? DesignTokens.darkBorder
                  : DesignTokens.border.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const Spacer(),
                if (badge != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(badge!,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: color)),
                  ),
              ],
            ),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11, color: DesignTokens.textSecondary)),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: (60 * index).ms,
          duration: 300.ms,
          curve: Curves.easeOut,
        )
        .slideY(begin: 0.06);
  }
}
