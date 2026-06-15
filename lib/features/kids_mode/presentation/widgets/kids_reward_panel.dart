import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsRewardPanel extends StatelessWidget {
  const KidsRewardPanel({
    super.key,
    required this.rewardProfile,
    this.onCompanionTap,
  });

  final Map<String, dynamic> rewardProfile;
  final ValueChanged<String>? onCompanionTap;

  @override
  Widget build(BuildContext context) {
    final level = (rewardProfile['level'] as num?)?.toInt() ?? 1;
    final xp = (rewardProfile['xp'] as num?)?.toInt() ?? 0;
    final coins = (rewardProfile['coins'] as num?)?.toInt() ?? 0;
    final progress =
        ((rewardProfile['progressToNextLevel'] as num?)?.toDouble() ?? 0)
            .clamp(0, 100);
    final companions =
        ((rewardProfile['availableCompanions'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
    final badges = ((rewardProfile['recentBadges'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: KidsVisualTheme.sunGold.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.auto_stories_rounded,
                    color: KidsVisualTheme.sunGold, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level Explorer',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: KidsVisualTheme.ink),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp xp · $coins coins',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: KidsVisualTheme.inkMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: progress / 100,
              backgroundColor: KidsVisualTheme.pathBlue.withValues(alpha: 0.12),
              color: KidsVisualTheme.pathBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${progress.round()}% to the next companion unlock',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: KidsVisualTheme.inkMuted),
          ),
          const SizedBox(height: 18),
          const Text(
            'Companions',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: KidsVisualTheme.ink),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 98,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: companions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = companions[index];
                final unlocked = item['unlocked'] == true;
                final equipped = item['equipped'] == true;
                return GestureDetector(
                  onTap: unlocked && onCompanionTap != null
                      ? () => onCompanionTap!(item['code'].toString())
                      : null,
                  child: Container(
                    width: 126,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: equipped
                          ? KidsVisualTheme.pathBlue.withValues(alpha: 0.14)
                          : unlocked
                              ? Colors.white
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: equipped
                            ? KidsVisualTheme.pathBlue
                            : Colors.black.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          unlocked
                              ? Icons.pets_rounded
                              : Icons.lock_outline_rounded,
                          color:
                              unlocked ? KidsVisualTheme.pathBlue : Colors.grey,
                        ),
                        const Spacer(),
                        Text(
                          item['title']?.toString() ?? 'Companion',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: KidsVisualTheme.ink),
                        ),
                        Text(
                          unlocked
                              ? (equipped ? 'Using now' : 'Tap to use')
                              : 'Level ${item['unlockLevel'] ?? '?'}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: KidsVisualTheme.inkMuted),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (badges.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'Recent badges',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: KidsVisualTheme.ink),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges.map((badge) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: KidsVisualTheme.sunGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        badge['title']?.toString() ?? 'Badge',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: KidsVisualTheme.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        badge['description']?.toString() ?? '',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: KidsVisualTheme.inkMuted),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
