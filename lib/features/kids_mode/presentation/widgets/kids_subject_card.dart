import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/animated_press.dart';
import '../../kids_visual_theme.dart';

class KidsSubjectCard extends StatelessWidget {
  const KidsSubjectCard({
    super.key,
    required this.name,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  final String name;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedPress(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: KidsVisualTheme.subjectTileShell(accent: accent, dark: dark),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.75)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.35),
                    offset: const Offset(0, 4),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: KidsVisualTheme.ink,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to learn',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: KidsVisualTheme.inkMuted.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.play_circle_fill_rounded, color: accent, size: 36),
          ],
        ),
      ),
    );
  }
}
