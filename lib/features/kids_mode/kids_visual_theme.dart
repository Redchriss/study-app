import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart' show DesignTokens;

/// Visual language for Yaza Kids: short sessions, obvious progress, large tap targets.
/// Influenced by bite-sized learning apps (clear hierarchy, “3D” CTAs, reward chips)
/// without copying third-party mascots or palettes.
class KidsVisualTheme {
  KidsVisualTheme._();

  static const Color pathBlue = Color(0xFF2B7FD9);
  static const Color trailGreen = Color(0xFF3DB86B);
  static const Color sunGold = Color(0xFFFFC02D);
  static const Color skyTop = Color(0xFF6BB8FF);
  static const Color skyMid = Color(0xFFB8DEFF);
  static const Color skyBottom = Color(0xFFF0F7FF);
  static const Color ink = Color(0xFF15324A);
  static const Color inkMuted = Color(0xFF5A7186);

  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [skyTop, skyMid, skyBottom],
        stops: [0.0, 0.35, 1.0],
      );

  static LinearGradient get ctaGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF52D178), trailGreen],
      );

  /// Softer overlay on existing [ThemeData] (keeps typography scale).
  static ThemeData overlayOn(ThemeData parent) {
    return parent.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: parent.appBarTheme.copyWith(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        iconTheme: const IconThemeData(color: ink),
        titleTextStyle: parent.textTheme.titleLarge?.copyWith(
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: parent.cardTheme.copyWith(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      textTheme: parent.textTheme.apply(
        bodyColor: ink,
        displayColor: ink,
      ),
    );
  }

  static List<BoxShadow> chunkyShadow(Color base, {double dy = 4}) => [
        BoxShadow(
          color: base.withValues(alpha: 0.45),
          offset: Offset(0, dy),
          blurRadius: 0,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  static BoxDecoration subjectTileShell({
    required Color accent,
    required bool dark,
  }) {
    return BoxDecoration(
      color: dark ? DesignTokens.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: accent.withValues(alpha: 0.35), width: 2),
      boxShadow: [
        BoxShadow(
          color: accent.withValues(alpha: 0.12),
          blurRadius: 0,
          offset: const Offset(0, 5),
        ),
        ...DesignTokens.shadowSm(dark),
      ],
    );
  }
}
