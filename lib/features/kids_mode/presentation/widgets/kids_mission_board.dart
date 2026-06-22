import '../../../../core/theme/design_tokens.dart';
import 'package:flutter/material.dart';

import '../../kids_visual_theme.dart';

class KidsMissionBoard extends StatelessWidget {
  const KidsMissionBoard({
    super.key,
    required this.readyReviewCount,
    required this.masteredCount,
    required this.inProgressCount,
    required this.untouchedCount,
    this.onReviewTap,
    this.onNextTap,
  });

  final int readyReviewCount;
  final int masteredCount;
  final int inProgressCount;
  final int untouchedCount;
  final VoidCallback? onReviewTap;
  final VoidCallback? onNextTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today\'s Missions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: KidsVisualTheme.ink,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Small wins help kids learn better than noisy rewards.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: KidsVisualTheme.inkMuted,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _MissionPill(
                      label: 'Review now',
                      value: '$readyReviewCount',
                      color: const Color(0xFFF39C12))),
              const SizedBox(width: 10),
              Expanded(
                  child: _MissionPill(
                      label: 'Mastered',
                      value: '$masteredCount',
                      color: const Color(0xFF2ECC71))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _MissionPill(
                      label: 'In progress',
                      value: '$inProgressCount',
                      color: KidsVisualTheme.pathBlue)),
              const SizedBox(width: 10),
              Expanded(
                  child: _MissionPill(
                      label: 'New topics',
                      value: '$untouchedCount',
                      color: const Color(0xFF9B59B6))),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MissionButton(
                label: readyReviewCount > 0 ? 'Start review' : 'Review later',
                onTap: readyReviewCount > 0 ? onReviewTap : null,
                color: const Color(0xFFF39C12),
              ),
              _MissionButton(
                label: 'Keep learning',
                onTap: onNextTap,
                color: KidsVisualTheme.pathBlue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissionPill extends StatelessWidget {
  const _MissionPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: KidsVisualTheme.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionButton extends StatelessWidget {
  const _MissionButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          onTap == null ? DesignTokens.border : color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: onTap == null ? DesignTokens.textTertiary : color,
            ),
          ),
        ),
      ),
    );
  }
}
