import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';

/// Reusable stat tile for the dashboard hero.
class HeroStatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color iconBg;
  final String? subtitle;

  const HeroStatTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.iconBg,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1)),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 8,
                          fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular progress ring for the daily goal stat.
class DailyGoalRingTile extends StatelessWidget {
  final double progress;
  final String value;
  final String label;

  const DailyGoalRingTile({
    super.key,
    required this.progress,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                ),
                Icon(Icons.today_rounded,
                    color: Colors.white.withValues(alpha: 0.8), size: 14),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1)),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of 7 streak dots shown when the user has an active streak.
class StreakDotsRow extends StatelessWidget {
  final int streak;
  final int dailyProgress;
  final int dailyGoal;

  const StreakDotsRow({
    super.key,
    required this.streak,
    required this.dailyProgress,
    required this.dailyGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedStreakFlame(streak: streak, size: 28),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              streak > 0 ? '$streak day streak!' : 'Start your streak',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              streak > 0
                  ? '${(dailyGoal - dailyProgress).clamp(0, dailyGoal)} questions remaining today'
                  : 'Complete ${dailyGoal} questions daily',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$dailyProgress/$dailyGoal',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
