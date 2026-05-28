import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsWorldMap extends StatelessWidget {
  const KidsWorldMap({
    super.key,
    required this.worlds,
    required this.onTopicTap,
  });

  final List<Map<String, dynamic>> worlds;
  final ValueChanged<String> onTopicTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: worlds.map((world) {
        final topics = ((world['topics'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final unlocked = world['unlocked'] == true;
        final completed = world['completed'] == true;
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: unlocked
                  ? Colors.white.withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: unlocked
                      ? Colors.white
                      : Colors.black.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: completed
                            ? const Color(0xFF2ECC71).withValues(alpha: 0.18)
                            : KidsVisualTheme.pathBlue.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        completed
                            ? Icons.emoji_events_rounded
                            : Icons.route_rounded,
                        color: completed
                            ? const Color(0xFF2ECC71)
                            : KidsVisualTheme.pathBlue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            world['title']?.toString() ?? 'World',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: KidsVisualTheme.ink),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            world['subtitle']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: KidsVisualTheme.inkMuted),
                          ),
                        ],
                      ),
                    ),
                    if (!unlocked)
                      const Icon(Icons.lock_outline_rounded,
                          color: KidsVisualTheme.inkMuted),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: topics.map((topic) {
                    final state = topic['state'] is Map
                        ? Map<String, dynamic>.from(topic['state'] as Map)
                        : null;
                    final ready = state?['readyForReview'] == true;
                    final mastered = state?['isMastered'] == true;
                    final accent = mastered
                        ? const Color(0xFF2ECC71)
                        : ready
                            ? const Color(0xFFF39C12)
                            : KidsVisualTheme.pathBlue;
                    return GestureDetector(
                      onTap: unlocked
                          ? () => onTopicTap(topic['topicId']?.toString() ?? '')
                          : null,
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              mastered
                                  ? Icons.check_circle_rounded
                                  : ready
                                      ? Icons.refresh_rounded
                                      : Icons.circle_outlined,
                              color: accent,
                              size: 18,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              topic['topicName']?.toString() ?? 'Topic',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: KidsVisualTheme.ink),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state?['statusLabel']?.toString() ?? 'Start here',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: accent),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
