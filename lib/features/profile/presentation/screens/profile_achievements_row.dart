import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';

class ProfileAchievementsRow extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const ProfileAchievementsRow({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: achievements.map((a) {
          final ach = a['achievement'] as Map<String, dynamic>?;
          final name = ach?['name']?.toString() ?? '';
          final category = ach?['category']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AchievementBadge(
              label: name,
              icon: _achIcon(category),
              color: _achColor(category),
              unlocked: true,
              size: 72,
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _achIcon(String cat) {
    switch (cat) {
      case 'community':
        return Icons.groups_rounded;
      case 'content':
        return Icons.article_rounded;
      case 'engagement':
        return Icons.chat_rounded;
      case 'milestone':
        return Icons.emoji_events_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  Color _achColor(String cat) {
    switch (cat) {
      case 'community':
        return const Color(0xFF7C4DFF);
      case 'content':
        return const Color(0xFF1B6CA8);
      case 'engagement':
        return const Color(0xFF2EC4B6);
      case 'milestone':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFFF4A261);
    }
  }
}
