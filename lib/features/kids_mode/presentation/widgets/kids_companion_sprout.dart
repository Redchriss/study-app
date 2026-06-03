import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'kids_companion_enums.dart';

class SproutBody extends StatelessWidget {
  const SproutBody({required this.mood, required this.animValue});
  final CompanionMood mood;
  final double animValue;

  @override
  Widget build(BuildContext context) {
    final eyeSize = mood == CompanionMood.celebration ? 4.0 : 3.0;
    final mouthSize =
        mood == CompanionMood.happy || mood == CompanionMood.celebration
            ? 6.0
            : mood == CompanionMood.encouraging
                ? 4.0
                : 2.0;
    final mouthY =
        mood == CompanionMood.happy || mood == CompanionMood.celebration
            ? -2.0
            : mood == CompanionMood.encouraging
                ? 0.0
                : 1.0;
    return CustomPaint(
      painter: SproutPainter(
        animValue: animValue,
        eyeSize: eyeSize,
        mouthSize: mouthSize,
        mouthY: mouthY,
        isCelebration: mood == CompanionMood.celebration,
      ),
    );
  }
}

class SproutPainter extends CustomPainter {
  SproutPainter({
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

    final potPaint = Paint()..color = const Color(0xFF8B5E3C);
    final stemPaint = Paint()
      ..color = const Color(0xFF3DB86B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final leafPaint = Paint()..color = const Color(0xFF52D178);
    final facePaint = Paint()..color = const Color(0xFF15324A);
    final blushPaint = Paint()
      ..color = const Color(0xFFFF8A80).withValues(alpha: 0.35);

    final potHeight = r * 0.35;
    final potTopY = cy + r * 0.2;
    final potPath = Path()
      ..moveTo(cx - r * 0.5, potTopY)
      ..lineTo(cx + r * 0.5, potTopY)
      ..lineTo(cx + r * 0.35, potTopY + potHeight)
      ..lineTo(cx - r * 0.35, potTopY + potHeight)
      ..close();
    canvas.drawPath(potPath, potPaint);

    final stemEndY = potTopY - r * 0.6;
    final sway = math.sin(animValue * math.pi * 2) * 2;
    final stemPath = Path()
      ..moveTo(cx, potTopY)
      ..quadraticBezierTo(
          cx + sway, potTopY - r * 0.3, cx + sway * 0.5, stemEndY);
    canvas.drawPath(stemPath, stemPaint);

    final leafSway = math.sin(animValue * math.pi * 2 + 1) * 3;
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - 8 + leafSway, stemEndY + 6),
          width: 10,
          height: 6),
      leafPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx + 8 + leafSway, stemEndY + 2),
          width: 10,
          height: 6),
      leafPaint,
    );

    final headCx = cx;
    final headCy = potTopY - r * 0.8;
    final headR = r * 0.35;
    canvas.drawCircle(Offset(headCx, headCy), headR,
        Paint()..color = const Color(0xFF52D178));

    canvas.drawCircle(Offset(headCx - 5, headCy - 1), eyeSize, facePaint);
    canvas.drawCircle(Offset(headCx + 5, headCy - 1), eyeSize, facePaint);

    canvas.drawCircle(Offset(headCx - 7, headCy + 4), 3, blushPaint);
    canvas.drawCircle(Offset(headCx + 7, headCy + 4), 3, blushPaint);

    final mouthPath = Path()
      ..moveTo(headCx - mouthSize, headCy + mouthY)
      ..quadraticBezierTo(
          headCx, headCy + mouthY + 3, headCx + mouthSize, headCy + mouthY);
    canvas.drawPath(
      mouthPath,
      Paint()
        ..color = const Color(0xFF15324A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    if (isCelebration) {
      for (var i = 0; i < 5; i++) {
        final angle = i * 1.256 + animValue * 2;
        final starR = r * 0.9;
        final sx = cx + math.cos(angle) * starR;
        final sy = cy - r * 0.4 + math.sin(angle) * starR * 0.5;
        canvas.drawCircle(
            Offset(sx, sy), 2.5, Paint()..color = const Color(0xFFFFC02D));
      }
    }
  }

  @override
  bool shouldRepaint(SproutPainter old) =>
      old.animValue != animValue || old.isCelebration != isCelebration;
}
