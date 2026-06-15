import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// An arc-shaped study progress meter with animated fill.
/// Replaces linear progress bars with a distinctive semicircular gauge.
class StudyMeterGauge extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String label;
  final String value;
  final Color? color;
  final double size;

  const StudyMeterGauge({
    super.key,
    required this.progress,
    required this.label,
    required this.value,
    this.color,
    this.size = 100,
  });

  @override
  State<StudyMeterGauge> createState() => _StudyMeterGaugeState();
}

class _StudyMeterGaugeState extends State<StudyMeterGauge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(StudyMeterGauge old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? DesignTokens.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _anim,
          builder: (context, _) {
            return CustomPaint(
              size: Size(widget.size, widget.size * 0.6),
              painter: _ArcPainter(
                progress: widget.progress * _anim.value,
                color: color,
                dark: Theme.of(context).brightness == Brightness.dark,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          widget.value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            height: 1,
          ),
        ),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool dark;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.dark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 8;
    const strokeWidth = 10.0;

    // Background arc
    final bgPaint = Paint()
      ..color = (dark ? Colors.white : Colors.black).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Progress arc
    if (progress > 0) {
      final fillGradient = LinearGradient(
        colors: [
          color.withValues(alpha: 0.7),
          color,
        ],
      );

      final fillPaint = Paint()
        ..shader = fillGradient.createShader(
          Rect.fromCircle(center: center, radius: radius + strokeWidth),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * progress.clamp(0.0, 1.0),
        false,
        fillPaint,
      );

      // Small glow dot at the tip
      if (progress > 0.02) {
        final tipAngle = math.pi + math.pi * progress.clamp(0.0, 1.0);
        final tipX = center.dx + math.cos(tipAngle) * radius;
        final tipY = center.dy + math.sin(tipAngle) * radius;
        final dotPaint = Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawCircle(Offset(tipX, tipY), 6, dotPaint);
        canvas.drawCircle(
          Offset(tipX, tipY),
          3,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) => old.progress != progress;
}
