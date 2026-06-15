import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// An animated flame streak indicator with organic fire-like animation.
/// Replaces the static orange dots in the dashboard hero header.
class AnimatedStreakFlame extends StatefulWidget {
  final int streak;
  final double size;

  const AnimatedStreakFlame({
    super.key,
    required this.streak,
    this.size = 32,
  });

  @override
  State<AnimatedStreakFlame> createState() => _AnimatedStreakFlameState();
}

class _AnimatedStreakFlameState extends State<AnimatedStreakFlame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.streak > 0;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _FlamePainter(
            progress: _ctrl.value,
            isActive: isActive,
            streak: widget.streak,
          ),
        );
      },
    );
  }
}

class _FlamePainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final int streak;

  _FlamePainter({
    required this.progress,
    required this.isActive,
    required this.streak,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    if (!isActive) {
      // Greyed-out ember for inactive streak
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius - 2, paint);
      return;
    }

    // Draw flame tiers based on streak milestones
    final tiers = streak >= 100 ? 3 : streak >= 30 ? 2 : streak >= 7 ? 2 : 1;
    final intensity = streak >= 100
        ? 1.0
        : streak >= 30
            ? 0.85
            : streak >= 7
                ? 0.7
                : 0.5;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFF9800).withValues(alpha: 0.3 * intensity),
          const Color(0xFFFF9800).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    // Flame body — animated flicker
    final flicker = math.sin(progress * 2 * math.pi) * 0.08;
    final flameH = radius * (0.6 + flicker);
    final flameW = radius * 0.5;

    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF6B00),
          const Color(0xFFFF9800),
          const Color(0xFFFFD700),
        ],
      ).createShader(Rect.fromLTWH(
        center.dx - flameW,
        center.dy - flameH,
        flameW * 2,
        flameH * 2,
      ));

    final flamePath = Path()
      ..moveTo(center.dx, center.dy - flameH)
      ..quadraticBezierTo(
        center.dx + flameW * 1.2,
        center.dy - flameH * 0.3,
        center.dx,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - flameW * 1.2,
        center.dy - flameH * 0.3,
        center.dx,
        center.dy - flameH,
      )
      ..close();

    canvas.drawPath(flamePath, flamePaint);

    // Inner bright core
    final corePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.8),
          const Color(0xFFFFD700).withValues(alpha: 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.4));
    canvas.drawCircle(
      center.translate(0, -radius * 0.1),
      radius * (0.2 + flicker * 0.5),
      corePaint,
    );

    // Milestone tiers
    for (int i = 0; i < tiers; i++) {
      final angle = -math.pi / 2 + (i - (tiers - 1) / 2) * 0.5;
      final dotX = center.dx + math.cos(angle) * radius * 0.85;
      final dotY = center.dy + math.sin(angle) * radius * 0.85;
      final dotPaint = Paint()..color = const Color(0xFFFFD700);
      canvas.drawCircle(
        Offset(dotX, dotY),
        2 + (math.sin(progress * 4 + i) * 0.5).abs(),
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FlamePainter old) =>
      old.progress != progress || old.isActive != isActive;
}
