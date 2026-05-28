import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

/// Yaza Material 3 theme — built entirely from DesignTokens.
/// Light + Dark, Dynamic Color support, consistent radii/spacing.

class AppTheme {
  static ThemeData light({Color? seed}) => _build(
        brightness: Brightness.light,
        seed: seed,
        bg: DesignTokens.background,
        surface: DesignTokens.surface,
        surfaceVariant: DesignTokens.surfaceVariant,
        border: DesignTokens.border,
        textPrimary: DesignTokens.textPrimary,
        textSecondary: DesignTokens.textSecondary,
        textTertiary: DesignTokens.textTertiary,
      );

  static ThemeData dark({Color? seed}) => _build(
        brightness: Brightness.dark,
        seed: seed,
        bg: DesignTokens.darkBackground,
        surface: DesignTokens.darkSurface,
        surfaceVariant: DesignTokens.darkSurfaceVariant,
        border: DesignTokens.darkBorder,
        textPrimary: DesignTokens.darkTextPrimary,
        textSecondary: DesignTokens.darkTextSecondary,
        textTertiary: DesignTokens.darkTextTertiary,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color surfaceVariant,
    required Color border,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    Color? seed,
  }) {
    final cs = ColorScheme.fromSeed(
      seedColor: seed ?? DesignTokens.primary,
      brightness: brightness,
      surface: surface,
      error: DesignTokens.error,
    );

    final textTheme = GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800, fontSize: 36, height: 1.1),
      displayMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800, fontSize: 32, height: 1.1),
      displaySmall: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700, fontSize: 28, height: 1.2),
      headlineLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700, fontSize: 24, height: 1.2),
      headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700, fontSize: 20, height: 1.3),
      headlineSmall: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600, fontSize: 18, height: 1.3),
      titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600, fontSize: 16, height: 1.4),
      titleMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
      bodyLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w400, fontSize: 16, height: 1.6),
      bodyMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w400, fontSize: 14, height: 1.5),
      labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600, fontSize: 14, height: 1.4),
      labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w500, fontSize: 11, height: 1.3),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          side: BorderSide(color: border.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spMd,
          vertical: DesignTokens.spSm,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
          elevation: 0,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: cs.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
                fontWeight: FontWeight.w600, fontSize: 12, color: cs.primary);
          }
          return GoogleFonts.inter(
              fontWeight: FontWeight.w500, fontSize: 12, color: textSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.primary, size: 24);
          }
          return IconThemeData(color: textSecondary, size: 24);
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        ),
      ),
    );
  }
}
