import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Skeleton loading box — pulses to indicate content loading.
/// Use instead of CircularProgressIndicator everywhere.

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  final Color? baseColor;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.radius = DesignTokens.radiusMd,
    this.baseColor,
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DesignTokens.durSlow * 3,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _a) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: (widget.baseColor ?? (dark ? DesignTokens.darkSurfaceVariant : DesignTokens.surfaceVariant))
              .withValues(alpha: _animation.value),
        ),
      ),
    );
  }
}
