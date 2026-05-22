import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.initials,
    required this.username,
    required this.email,
    required this.level,
    required this.plan,
    required this.streak,
    required this.points,
    required this.credits,
    required this.dark,
  });

  final String initials, username, email, level, plan;
  final dynamic streak, points, credits;
  final bool dark;

  static const _levelColors = {
    'primary': Color(0xFF27AE60),
    'secondary': Color(0xFF1B6CA8),
    'tertiary': Color(0xFF7A4D9E),
  };

  @override
  Widget build(BuildContext context) {
    final levelColor = _levelColors[level] ?? DesignTokens.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [levelColor.withValues(alpha: 0.85), levelColor.withValues(alpha: 0.55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusXxl),
        boxShadow: DesignTokens.shadowMd(dark),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
                ),
                child: Center(
                  child: Text(initials, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(username, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(email, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        HeroBadge(label: _levelLabel(level)),
                        const SizedBox(width: 6),
                        HeroBadge(label: plan, icon: Icons.star_rounded),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatPill(icon: Icons.local_fire_department, value: '$streak', label: 'Streak', color: Colors.orange),
              const SizedBox(width: 8),
              StatPill(icon: Icons.stars_rounded, value: '$points', label: 'Points', color: Colors.amber),
              const SizedBox(width: 8),
              StatPill(icon: Icons.bolt_rounded, value: '$credits', label: 'Credits', color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  static String _levelLabel(String level) {
    switch (level) {
      case 'primary': return 'Primary';
      case 'tertiary': return 'Tertiary';
      default: return 'Secondary';
    }
  }
}

class HeroBadge extends StatelessWidget {
  const HeroBadge({super.key, required this.label, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 11, color: Colors.amber), const SizedBox(width: 4)],
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
        ],
      ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.icon, required this.value, required this.label, required this.color});
  final IconData icon;
  final String value, label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
