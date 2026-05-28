import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';

class ScannerImagePreview extends StatelessWidget {
  final File image;
  final Animation<double> laserAnimation;
  final bool solving;

  const ScannerImagePreview({
    super.key,
    required this.image,
    required this.laserAnimation,
    required this.solving,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: DesignTokens.primary.withValues(alpha: 0.2), width: 2),
        boxShadow: DesignTokens.shadowSm(dark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              image,
              fit: BoxFit.cover,
              color: solving
                  ? const Color(0xFF10B981).withValues(alpha: 0.2)
                  : null,
              colorBlendMode: solving ? BlendMode.overlay : null,
            ),
            if (solving)
              AnimatedBuilder(
                animation: laserAnimation,
                builder: (context, child) {
                  return Positioned(
                    top: laserAnimation.value * 220,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.8),
                            blurRadius: 15,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF10B981).withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            if (solving)
              Container(
                color: Colors.black.withValues(alpha: 0.4),
                child: const Center(
                  child: Text(
                    'Scanning Document...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
