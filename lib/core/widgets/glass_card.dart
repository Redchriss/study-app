import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Frosted-glass card with blur and transparency.
/// Use for modals, elevated sections, and emphasis cards.

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final double opacity;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.blur = 20,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? const EdgeInsets.all(DesignTokens.spLg),
          decoration: DesignTokens.glassDecoration(dark, blur: blur, opacity: opacity),
          child: child,
        ),
      ),
    );
  }
}
