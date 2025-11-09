import 'package:flutter/material.dart';
import '../utils/safe_fonts.dart';

/// Design Tokens - Spacing, Typography, Radii, Elevation
class DesignTokens {
  // Spacing (8pt grid)
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;

  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusRound = 999.0;

  // Elevation / Shadows
  static List<BoxShadow> shadowSM = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMD = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLG = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> shadowXL = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  // Icon Sizes
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // Typography Scale
  static TextTheme getTextTheme(bool isDark) {
    final baseColor = isDark ? const Color(0xFFF5EDE0) : const Color(0xFF2A1E1A);
    final secondaryColor = isDark ? const Color(0xFFA1887F) : const Color(0xFFA1887F);

    return TextTheme(
      // Display
      displayLarge: SafeFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: baseColor,
        letterSpacing: -1.0,
        height: 1.2,
      ),
      displayMedium: SafeFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: baseColor,
        letterSpacing: -0.8,
        height: 1.2,
      ),
      displaySmall: SafeFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: baseColor,
        letterSpacing: -0.6,
        height: 1.3,
      ),

      // Headlines
      headlineLarge: SafeFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: baseColor,
        letterSpacing: -0.4,
        height: 1.3,
      ),
      headlineMedium: SafeFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: -0.3,
        height: 1.4,
      ),
      headlineSmall: SafeFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),

      // Titles
      titleLarge: SafeFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleMedium: SafeFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),
      titleSmall: SafeFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        height: 1.4,
      ),

      // Body
      bodyLarge: SafeFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 1.6,
      ),
      bodyMedium: SafeFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: baseColor,
        height: 1.5,
      ),
      bodySmall: SafeFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryColor,
        height: 1.4,
      ),

      // Labels
      labelLarge: SafeFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      labelMedium: SafeFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: baseColor,
        letterSpacing: 0.5,
        height: 1.4,
      ),
      labelSmall: SafeFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: secondaryColor,
        letterSpacing: 0.5,
        height: 1.3,
      ),
    );
  }

  // Animation Durations
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  // Tappable Area
  static const double tappableArea = 44.0;
}

