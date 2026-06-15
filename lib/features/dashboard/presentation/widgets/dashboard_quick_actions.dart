import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _ActionTile(
            icon: Icons.menu_book_rounded,
            label: 'Study',
            color: DesignTokens.primary,
            onTap: () => context.push('/materials')),
        _ActionTile(
            icon: Icons.quiz_rounded,
            label: 'Quiz',
            color: DesignTokens.secondary,
            onTap: () => context.push('/quizzes')),
        _ActionTile(
            icon: Icons.document_scanner_rounded,
            label: 'Scanner',
            color: const Color(0xFF2EC4B6),
            onTap: () => context.push('/scanner')),
        _ActionTile(
            icon: Icons.rocket_launch_rounded,
            label: 'AI Tutor',
            color: const Color(0xFF7C4DFF),
            onTap: () => context.push('/ai-tutor')),
        _ActionTile(
            icon: Icons.emoji_events_rounded,
            label: 'Ranks',
            color: const Color(0xFFFFC107),
            onTap: () => context.push('/leaderboard')),
        _ActionTile(
            icon: Icons.child_care_rounded,
            label: 'Kids',
            color: const Color(0xFFE87E5E),
            onTap: () => context.push('/kids')),
        _ActionTile(
            icon: Icons.upload_file_rounded,
            label: 'Upload',
            color: DesignTokens.accent,
            onTap: () => context.push('/upload-material')),
        _ActionTile(
            icon: Icons.groups_rounded,
            label: 'Circles',
            color: DesignTokens.info,
            onTap: () => context.go('/home')),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedPress(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: color.withValues(alpha: 0.2), width: 1.5)),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700, fontSize: 11),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
