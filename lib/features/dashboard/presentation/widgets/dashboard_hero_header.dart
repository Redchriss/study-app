import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/design_tokens.dart';

class DashboardHeroHeader extends StatelessWidget {
  final String name;
  final String educationLevel;
  final int streak;
  final int points;
  final int credits;
  final bool dark;
  final VoidCallback onNotification;
  final VoidCallback onAiTutor;

  const DashboardHeroHeader({
    super.key,
    required this.name,
    required this.educationLevel,
    required this.streak,
    required this.points,
    required this.credits,
    required this.dark,
    required this.onNotification,
    required this.onAiTutor,
  });

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _levelLabel {
    switch (educationLevel.toLowerCase()) {
      case 'primary': return 'Primary student';
      case 'tertiary': return 'University student';
      default: return 'Secondary student';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B6CA8), Color(0xFF0D2E4A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_greeting,', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14, fontWeight: FontWeight.w500)),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -0.5)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(999)),
                          child: Text(_levelLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24), onPressed: onNotification),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                children: [
                  _HeroStat(value: streak.toString(), label: 'Streak', icon: Icons.local_fire_department_rounded, color: const Color(0xFFFF9800), iconBg: const Color(0x33FF9800)),
                  const SizedBox(width: 10),
                  _HeroStat(value: points.toString(), label: 'Points', icon: Icons.star_rounded, color: const Color(0xFFFFD700), iconBg: const Color(0x33FFD700)),
                  const SizedBox(width: 10),
                  _HeroStat(value: credits.toString(), label: 'Credits', icon: Icons.bolt_rounded, color: const Color(0xFF69F0AE), iconBg: const Color(0x3369F0AE)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: onAiTutor,
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: const Color(0xFF69F0AE).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF69F0AE), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Ask AI Tutor anything...', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14, fontWeight: FontWeight.w500))),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.5), size: 14),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 24,
              decoration: BoxDecoration(
                color: dark ? DesignTokens.darkBackground : DesignTokens.background,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final Color iconBg;
  const _HeroStat({required this.value, required this.label, required this.icon, required this.color, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(width: 30, height: 30, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1)),
                  Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 9, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
