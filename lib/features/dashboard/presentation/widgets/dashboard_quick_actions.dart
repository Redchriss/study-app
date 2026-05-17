import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class DashboardQuickActions extends StatelessWidget {
  final String educationLevel;
  final int circlesCount;
  const DashboardQuickActions({super.key, required this.educationLevel, required this.circlesCount});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _ActionTile(icon: Icons.document_scanner_rounded, label: 'Solve Paper', color: const Color(0xFF2EC4B6), onTap: () => context.push('/scanner')),
        _ActionTile(icon: Icons.menu_book_rounded, label: 'Study', color: DesignTokens.primary, onTap: () => context.push('/materials')),
        _ActionTile(icon: Icons.quiz_rounded, label: 'Quiz', color: DesignTokens.secondary, onTap: () => context.push('/quizzes')),
        _ActionTile(icon: Icons.auto_awesome_rounded, label: 'AI', color: const Color(0xFF7C4DFF), onTap: () => context.push('/ai-tutor')),
        _ActionTile(icon: Icons.groups_rounded, label: 'Circles', color: const Color(0xFFE91E63), onTap: () => context.push('/circles'), badge: circlesCount > 0 ? circlesCount.toString() : null),
        _ActionTile(icon: Icons.article_rounded, label: 'Papers', color: const Color(0xFFF39C12), onTap: () => context.push('/paper-library')),
        _ActionTile(icon: Icons.upload_file_rounded, label: 'Upload', color: const Color(0xFF1F6A52), onTap: () => context.push('/upload-material')),
        _ActionTile(icon: Icons.emoji_events_rounded, label: 'Rank', color: const Color(0xFFFF6B35), onTap: () => context.push('/leaderboard')),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? badge;
  const _ActionTile({required this.icon, required this.label, required this.color, required this.onTap, this.badge});

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
                width: 54, height: 54,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5)),
                child: Icon(icon, color: color, size: 24),
              ),
              if (badge != null)
                Positioned(
                  top: -4, right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: DesignTokens.error, shape: BoxShape.circle),
                    child: Text(badge!, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 11), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
