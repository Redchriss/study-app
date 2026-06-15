import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

/// A custom-painted background that creates 'Elite' organic orbs
/// with Gaussian-style blurring.
class SoftMeshBackground extends StatelessWidget {
  final Color baseColor;
  final Color accentColor;
  
  const SoftMeshBackground({
    super.key,
    required this.baseColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: baseColor),
        Positioned.fill(
          child: CustomPaint(
            painter: _MeshPainter(accentColor: accentColor),
          ),
        ).animate(onPlay: (c) => c.repeat())
         .custom(
           duration: 10.seconds,
           builder: (context, value, child) => Opacity(
             opacity: 0.1 + (0.05 * math.sin(value * 2 * math.pi)),
             child: child,
           ),
         ),
      ],
    );
  }
}

class _MeshPainter extends CustomPainter {
  final Color accentColor;
  _MeshPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accentColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      size.width * 0.4,
      paint,
    );
    
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      size.width * 0.5,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
