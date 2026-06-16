import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom-painted achievement badge with ribbon and star emblem.
/// Distinctive from stock Material icons — gives Yaza its own visual language.
class AchievementBadge extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool unlocked;
  final double size;

  const AchievementBadge({
    super.key,
    required this.label,
    required this.icon,
    this.color = const Color(0xFFFFD700),
    this.unlocked = true,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomPaint(
            size: Size(size, size * 0.85),
            painter: _BadgePainter(
              color: unlocked ? color : Colors.grey,
              unlocked: unlocked,
            ),
            child: Center(
              child: Icon(
                icon,
                size: size * 0.35,
                color: unlocked ? Colors.white : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: unlocked
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  final Color color;
  final bool unlocked;

  _BadgePainter({required this.color, required this.unlocked});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.4;
    final outerR = math.min(size.width, size.height * 0.9) / 2;
    final innerR = outerR * 0.75;

    // Shadow
    if (unlocked) {
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, cy), outerR * 0.9, shadowPaint);
    }

    // Outer circle with gradient
    final badgePaint = Paint()
      ..shader = RadialGradient(
        colors: unlocked
            ? [color, color.withValues(alpha: 0.6), color.withValues(alpha: 0.8)]
            : [Colors.grey.shade300, Colors.grey.shade500],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: outerR));

    final outerPath = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: outerR));
    canvas.drawPath(outerPath, badgePaint);

    // Border ring
    final ringPaint = Paint()
      ..color = unlocked ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(Offset(cx, cy), outerR - 2, ringPaint);

    // Inner star shape (for unlocked) or lock shape (for locked)
    if (unlocked) {
      final starPaint = Paint()..color = Colors.white.withValues(alpha: 0.3);
      final starPath = Path();
      final points = 5;
      for (int i = 0; i < points * 2; i++) {
        final r = i.isEven ? innerR * 0.5 : innerR * 0.25;
        final angle = -math.pi / 2 + (math.pi / points) * i;
        final px = cx + math.cos(angle) * r;
        final py = cy + math.sin(angle) * r;
        if (i == 0) {
          starPath.moveTo(px, py);
        } else {
          starPath.lineTo(px, py);
        }
      }
      starPath.close();
      canvas.drawPath(starPath, starPaint);
    } else {
      // Simple lock dot
      final lockPaint = Paint()..color = Colors.grey.shade400;
      canvas.drawCircle(Offset(cx, cy), innerR * 0.3, lockPaint);
    }

    // Rays for unlocked
    if (unlocked) {
      final rayPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (int i = 0; i < 8; i++) {
        final angle = (math.pi / 4) * i;
        final rStart = outerR + 4;
        final rEnd = outerR + 10;
        canvas.drawLine(
          Offset(cx + math.cos(angle) * rStart, cy + math.sin(angle) * rStart),
          Offset(cx + math.cos(angle) * rEnd, cy + math.sin(angle) * rEnd),
          rayPaint,
        );
      }
    }

    // Bottom ribbon
    final ribbonPath = Path()
      ..moveTo(cx - outerR * 0.6, cy + outerR * 0.5)
      ..lineTo(cx, cy + outerR * 0.9)
      ..lineTo(cx + outerR * 0.6, cy + outerR * 0.5)
      ..lineTo(cx + outerR * 0.4, cy + outerR * 0.3)
      ..lineTo(cx - outerR * 0.4, cy + outerR * 0.3)
      ..close();

    final ribbonPaint = Paint()
      ..color = unlocked
          ? color.withValues(alpha: 0.8)
          : Colors.grey.withValues(alpha: 0.4);
    canvas.drawPath(ribbonPath, ribbonPaint);
  }

  @override
  bool shouldRepaint(covariant _BadgePainter old) =>
      old.color != color || old.unlocked != unlocked;
}
