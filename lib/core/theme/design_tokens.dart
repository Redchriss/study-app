import 'package:flutter/material.dart';

/// ─── Design Tokens ─────────────────────────────────────────────────────
/// Single source of truth for every visual property in Yaza.
/// No hardcoded values anywhere in features — import these.

class DesignTokens {
  DesignTokens._();

  // ── Brand ────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A1A6B);      // Deep navy — premium, trustworthy
  static const Color primaryLight = Color(0xFF3D5AFE); // Vibrant indigo — for gradients
  static const Color secondary = Color(0xFFF5A623);    // Warm gold — African sun, aspirational
  static const Color accent = Color(0xFF00C9A7);       // Emerald teal — fresh, energetic CTA

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00C853);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF1744);
  static const Color info = Color(0xFF448AFF);

  // ── Surfaces (light) ─────────────────────────────────────────────────
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F3F5);
  static const Color border = Color(0xFFE9ECEF);
  static const Color borderLight = Color(0xFFDEE2E6);

  // ── Surfaces (dark) ──────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0E17);     // Richer midnight
  static const Color darkSurface = Color(0xFF121926);        // Slightly lighter card surface
  static const Color darkSurfaceVariant = Color(0xFF1C2333); // Input fills
  static const Color darkBorder = Color(0xFF2D3548);         // Subtle blue-tinted border

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF17172B);
  static const Color textSecondary = Color(0xFF5A6476);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color darkTextPrimary = Color(0xFFEDF2F7);
  static const Color darkTextSecondary = Color(0xFF7F8EA3);
  static const Color darkTextTertiary = Color(0xFF596580);

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

  // ── Signature brand gradients ────────────────────────────────────────
  /// The primary Yaza gradient (deep navy → vibrant indigo). Use sparingly
  /// for hero surfaces, accents, and the AI presence so the brand reads as
  /// unmistakably Yaza rather than a generic flat theme.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// A low-emphasis tint of the brand gradient for card washes / chips.
  static LinearGradient brandGradientSubtle(bool dark) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          primary.withValues(alpha: dark ? 0.18 : 0.06),
          primaryLight.withValues(alpha: dark ? 0.10 : 0.03),
        ],
      );

  // ── Signature card surface ───────────────────────────────────────────
  /// The signature Yaza card: rounded, hairline-bordered, softly elevated.
  /// Shared seam for the redesign so every feature card reads consistently.
  static BoxDecoration signatureSurface(bool dark,
      {double radius = radiusLg, bool elevated = true}) {
    return BoxDecoration(
      color: dark ? darkSurface : surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: (dark ? darkBorder : border).withValues(alpha: dark ? 0.7 : 1),
      ),
      boxShadow: elevated ? shadowSm(dark) : null,
    );
  }

  // ── Breakpoints ──────────────────────────────────────────────────────
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
}
