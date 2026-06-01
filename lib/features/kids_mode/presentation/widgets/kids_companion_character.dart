import 'dart:math' as math;

import 'package:flutter/material.dart';

enum CompanionMood { idle, happy, encouraging, celebration }

enum CompanionType { sprout, flame, none }

class KidsCompanionCharacter extends StatefulWidget {
  const KidsCompanionCharacter({
    super.key,
    this.type = CompanionType.sprout,
    this.mood = CompanionMood.idle,
    this.size = 80,
  });

  final CompanionType type;
  final CompanionMood mood;
  final double size;

  @override
  State<KidsCompanionCharacter> createState() => _KidsCompanionCharacterState();
}

class _KidsCompanionCharacterState extends State<KidsCompanionCharacter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(KidsCompanionCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mood == CompanionMood.celebration &&
        oldWidget.mood != widget.mood) {
      _ctrl.repeat(period: const Duration(milliseconds: 300), reverse: true);
    } else if (widget.mood != CompanionMood.celebration) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.type == CompanionType.sprout
          ? 'Sprout the plant companion'
          : 'Flame the fire companion',
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final idleBob = math.sin(_ctrl.value * math.pi) * 4;
          final celebrationScale = widget.mood == CompanionMood.celebration
              ? 1.0 + _ctrl.value * 0.15
              : 1.0;
          return Transform.translate(
            offset: Offset(0, -idleBob),
            child: Transform.scale(
              scale: celebrationScale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: widget.type == CompanionType.sprout
                    ? _SproutBody(mood: widget.mood, animValue: _ctrl.value)
                    : _FlameBody(mood: widget.mood, animValue: _ctrl.value),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SproutBody extends StatelessWidget {
  const _SproutBody({required this.mood, required this.animValue});
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
      painter: _SproutPainter(
        animValue: animValue,
        eyeSize: eyeSize,
        mouthSize: mouthSize,
        mouthY: mouthY,
        isCelebration: mood == CompanionMood.celebration,
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({
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
  bool shouldRepaint(_SproutPainter old) =>
      old.animValue != animValue || old.isCelebration != isCelebration;
}

class _FlameBody extends StatelessWidget {
  const _FlameBody({required this.mood, required this.animValue});
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
      painter: _FlamePainter(
        animValue: animValue,
        eyeSize: eyeSize,
        mouthSize: mouthSize,
        mouthY: mouthY,
        isCelebration: mood == CompanionMood.celebration,
      ),
    );
  }
}

class _FlamePainter extends CustomPainter {
  _FlamePainter({
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
  bool shouldRepaint(_FlamePainter old) =>
      old.animValue != animValue || old.isCelebration != isCelebration;
}

class KidsCompanionMessage extends StatelessWidget {
  const KidsCompanionMessage({
    super.key,
    required this.message,
    this.type = CompanionType.sprout,
  });

  final String message;
  final CompanionType type;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            KidsCompanionCharacter(type: type, size: 32),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15324A),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
