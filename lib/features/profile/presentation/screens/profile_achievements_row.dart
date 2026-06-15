import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ProfileAchievementsRow extends StatelessWidget {
  final List<Map<String, dynamic>> achievements;

  const ProfileAchievementsRow({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: achievements.map((a) {
          final ach = a['achievement'] as Map<String, dynamic>?;
          final name = ach?['name']?.toString() ?? '';
          final iconUrl = ach?['iconUrl']?.toString() ?? '';
          final category = ach?['category']?.toString() ?? '';
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: iconUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(iconUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                  _achIcon(category),
                                  color: DesignTokens.primary,
                                  size: 22)),
                        )
                      : Icon(_achIcon(category),
                          color: DesignTokens.primary, size: 22),
                ),
                const SizedBox(height: 4),
                Text(name,
                    style: const TextStyle(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
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
        return Icons.workspace_premium_rounded;
    }
  }
}
