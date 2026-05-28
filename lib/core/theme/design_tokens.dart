import 'package:flutter/material.dart';

/// ─── Design Tokens ─────────────────────────────────────────────────────
/// Single source of truth for every visual property in Yaza.
/// No hardcoded values anywhere in features — import these.

class DesignTokens {
  DesignTokens._();

  // ── Brand ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1B6CA8);
  static const Color primaryLight = Color(0xFF4A90D9);
  static const Color secondary = Color(0xFFF4A261);
  static const Color accent = Color(0xFF2EC4B6);

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF27AE60);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // ── Surfaces (light) ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  static const Color border = Color(0xFFE9ECEF);
  static const Color borderLight = Color(0xFFDEE2E6);

  // ── Surfaces (dark) ──────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkSurfaceVariant = Color(0xFF21262D);
  static const Color darkBorder = Color(0xFF30363D);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textTertiary = Color(0xFFADB5BD);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color darkTextPrimary = Color(0xFFF0F6FC);
  static const Color darkTextSecondary = Color(0xFF8B949E);
  static const Color darkTextTertiary = Color(0xFF6E7681);

  // ── Corner Radii ─────────────────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusXxl = 28;

  // ── Spacing ──────────────────────────────────────────────────────────
  static const double spXxs = 4;
  static const double spXs = 8;
  static const double spSm = 12;
  static const double spMd = 16;
  static const double spLg = 20;
  static const double spXl = 24;
  static const double spXxl = 32;
  static const double spXxxl = 48;

  // ── Durations (for animations) ───────────────────────────────────────
  static const Duration durInstant = Duration(milliseconds: 100);
  static const Duration durFast = Duration(milliseconds: 200);
  static const Duration durNormal = Duration(milliseconds: 300);
  static const Duration durSlow = Duration(milliseconds: 500);

  // ── Springs (mass, stiffness, damping) ───────────────────────────────
  static const springSnappy = (3.0, 300.0, 25.0);
  static const springGentle = (5.0, 200.0, 20.0);
  static const springBouncy = (2.0, 200.0, 15.0);

  // ── Shadows ──────────────────────────────────────────────────────────
  static List<BoxShadow> shadowSm(bool dark) => [
        BoxShadow(
          color: (dark ? Colors.black : Colors.black)
              .withValues(alpha: dark ? 0.3 : 0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> shadowMd(bool dark) => [
        BoxShadow(
          color: (dark ? Colors.black : Colors.black)
              .withValues(alpha: dark ? 0.4 : 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> shadowLg(bool dark) => [
        BoxShadow(
          color: (dark ? Colors.black : Colors.black)
              .withValues(alpha: dark ? 0.5 : 0.1),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ── Glassmorphism ────────────────────────────────────────────────────
  static BoxDecoration glassDecoration(bool dark,
      {double blur = 20, double opacity = 0.6}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radiusXl),
      color: (dark ? darkSurface : surface).withValues(alpha: opacity),
      border: Border.all(
        color: (dark ? darkBorder : border).withValues(alpha: 0.3),
      ),
    );
  }

  // ── Breakpoints ──────────────────────────────────────────────────────
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
}
