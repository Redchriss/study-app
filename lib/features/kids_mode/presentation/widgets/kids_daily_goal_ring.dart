import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';

/// Today’s learning ring (goal-setting + progress visibility; keep goals small to reduce pressure).
class KidsDailyGoalRing extends StatelessWidget {
  const KidsDailyGoalRing({
    super.key,
    required this.activities,
    required this.goal,
    this.size = 72,
    this.stroke = 7,
  });

  final int activities;
  final int goal;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final g = goal <= 0 ? 1 : goal;
    final p = (activities / g).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: p,
            strokeWidth: stroke,
            strokeCap: StrokeCap.round,
            backgroundColor: KidsVisualTheme.ink.withValues(alpha: 0.08),
            color: KidsVisualTheme.pathBlue,
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$activities',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ).copyWith(color: KidsVisualTheme.ink),
                ),
                Text(
                  '/$g',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KidsVisualTheme.inkMuted.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight “buddy” + copy (no third-party mascot assets).
class KidsMascotHint extends StatelessWidget {
  const KidsMascotHint({
    super.key,
    required this.message,
    this.emoji = '🌟',
  });

  final String message;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KidsVisualTheme.sunGold.withValues(alpha: 0.45), width: 2),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ).copyWith(color: KidsVisualTheme.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class KidsDailyChestChip extends StatelessWidget {
  const KidsDailyChestChip({
    super.key,
    required this.available,
    required this.claimed,
    required this.onClaim,
  });

  final bool available;
  final bool claimed;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final String label;
    final IconData icon;
    final Color bg;
    if (claimed) {
      label = 'Opened!';
      icon = Icons.inventory_2_rounded;
      bg = KidsVisualTheme.inkMuted.withValues(alpha: 0.2);
    } else if (available) {
      label = 'Open reward';
      icon = Icons.redeem_rounded;
      bg = KidsVisualTheme.sunGold.withValues(alpha: 0.35);
    } else {
      label = 'Reward';
      icon = Icons.lock_rounded;
      bg = KidsVisualTheme.ink.withValues(alpha: 0.06);
    }
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: available && !claimed ? onClaim : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: KidsVisualTheme.ink, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w800, color: KidsVisualTheme.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
