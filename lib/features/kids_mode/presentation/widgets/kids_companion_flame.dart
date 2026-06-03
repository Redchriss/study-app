import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'kids_companion_enums.dart';

class FlameBody extends StatelessWidget {
  const FlameBody({required this.mood, required this.animValue});
  final CompanionMood mood;
  final double animValue;

  @override
  Widget build(BuildContext context) {
    final eyeSize = mood == CompanionMood.celebration ? 4.0 : 3.0;
    final mouthSize =
        mood == CompanionMood.happy || mood == CompanionMood.celebration
            ? 5.0
            : mood == CompanionMood.encouraging
                ? 3.5
                : 1.5;
    final mouthY =
        mood == CompanionMood.happy || mood == CompanionMood.celebration
            ? -1.5
            : mood == CompanionMood.encouraging
                ? 0.5
                : 1.5;
    return CustomPaint(
      painter: FlamePainter(
        animValue: animValue,
        eyeSize: eyeSize,
        mouthSize: mouthSize,
        mouthY: mouthY,
        isCelebration: mood == CompanionMood.celebration,
      ),
    );
  }
}

class FlamePainter extends CustomPainter {
  FlamePainter({
    required this.animValue,
    required this.eyeSize,
    required this.mouthSize,
    required this.mouthY,
    required this.isCelebration,
  });

  final double animValue;
  final double eyeSize;
  final double mouthSize;
  final double mouthY;
  final bool isCelebration;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;

    final flicker = math.sin(animValue * math.pi * 3) * 3;

    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF6B35),
          const Color(0xFFFFC02D),
          const Color(0xFFFFE082)
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final flamePath = Path()
      ..moveTo(cx, cy - r + flicker)
      ..quadraticBezierTo(cx - r * 0.5, cy - r * 0.3, cx - r * 0.25, cy)
      ..quadraticBezierTo(cx - r * 0.15, cy + r * 0.15, cx, cy + r * 0.1)
      ..quadraticBezierTo(cx + r * 0.15, cy + r * 0.15, cx + r * 0.25, cy)
      ..quadraticBezierTo(cx + r * 0.5, cy - r * 0.3, cx, cy - r + flicker)
      ..close();
    canvas.drawPath(flamePath, flamePaint);

    final headCx = cx;
    final headCy = cy - r * 0.15;
    final facePaintColor = const Color(0xFF5D2E0E);

    canvas.drawCircle(Offset(headCx - 5, headCy - 2), eyeSize,
        Paint()..color = facePaintColor);
    canvas.drawCircle(Offset(headCx + 5, headCy - 2), eyeSize,
        Paint()..color = facePaintColor);

    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.3);
    canvas.drawCircle(Offset(headCx - 7, headCy + 3), 2.5, blushPaint);
    canvas.drawCircle(Offset(headCx + 7, headCy + 3), 2.5, blushPaint);

    final mouthPath = Path()
      ..moveTo(headCx - mouthSize, headCy + mouthY)
      ..quadraticBezierTo(
          headCx, headCy + mouthY + 2.5, headCx + mouthSize, headCy + mouthY);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = facePaintColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (isCelebration) {
      for (var i = 0; i < 6; i++) {
        final angle = i * 1.047 + animValue * 3;
        final sparkR = r * 0.85;
        final sx = cx + math.cos(angle) * sparkR;
        final sy = cy + math.sin(angle) * sparkR * 0.6;
        canvas.drawCircle(
          Offset(sx, sy),
          2 + math.sin(animValue * 5 + i) * 1,
          Paint()..color = const Color(0xFFFFC02D),
        );
      }
    }
  }

  @override
  bool shouldRepaint(FlamePainter old) =>
      old.animValue != animValue || old.isCelebration != isCelebration;
}
