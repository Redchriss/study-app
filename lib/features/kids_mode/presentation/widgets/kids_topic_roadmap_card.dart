import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsTopicRoadmapCard extends StatelessWidget {
  const KidsTopicRoadmapCard({
    super.key,
    required this.title,
    required this.statusLabel,
    required this.masteryLevel,
    required this.selected,
    required this.readyForReview,
    required this.isMastered,
    this.nextReviewLabel,
    this.onTap,
  });

  final String title;
  final String statusLabel;
  final int masteryLevel;
  final bool selected;
  final bool readyForReview;
  final bool isMastered;
  final String? nextReviewLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = readyForReview
        ? const Color(0xFFF39C12)
        : isMastered
            ? const Color(0xFF2ECC71)
            : KidsVisualTheme.pathBlue;
    return Material(
      color: selected
          ? accent.withValues(alpha: 0.18)
          : Colors.white.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 180,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? accent : Colors.white),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(
                      index < masteryLevel
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 16,
                      color: accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: KidsVisualTheme.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
              if (nextReviewLabel != null &&
                  nextReviewLabel!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  nextReviewLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: KidsVisualTheme.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
