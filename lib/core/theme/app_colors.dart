import 'package:flutter/material.dart';

/// Dark Brown Elegant Color Palette
/// Complete design system colors for Light & Dark modes
class AppColors {
  // Base Colors
  static const Color darkBrown = Color(0xFF3E2723);
  static const Color secondaryBrown = Color(0xFF4E342E);
  static const Color premiumGold = Color(0xFFD4AF37);
  static const Color milkCream = Color(0xFFF5EDE0);
  static const Color caramelBeige = Color(0xFFA1887F);
  static const Color matteBlack = Color(0xFF1C1C1C);
  static const Color lightText = Color(0xFFF5EDE0);
  static const Color darkText = Color(0xFF2A1E1A);

  // Card Colors
  static const Color cardLight = Color(0xFFBCAAA4); // soft brown
  static const Color cardDark = Color(0xFF4E342E); // secondary brown

  // Semantic Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);
  static const Color royalPurple = Color(0xFF9C27B0);
  static const Color accentTeal = Color(0xFF009688);

  // Light Mode Palette
  static const LightColors light = LightColors();

  // Dark Mode Palette
  static const DarkColors dark = DarkColors();

  // Gradients
  static LinearGradient get goldGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [premiumGold, Color(0xFFB8941F)],
      );

  static LinearGradient get brownGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [darkBrown, secondaryBrown],
      );

  static LinearGradient get creamGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [milkCream, Color(0xFFEDE0D1)],
      );

  // Aliases for backward compatibility
  static const Color coffeeCream = caramelBeige;
  static const Color offWhite = milkCream;
  static const Color espresso = darkBrown;
  static const Color goldAccent = premiumGold;
  static const Color caramel = caramelBeige;
  static const Color marron = darkBrown;
  static const Color beige = caramelBeige;
  static const Color creme = milkCream;
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Colors.grey;
}

class LightColors {
  const LightColors();

  Color get background => AppColors.milkCream;
  Color get card => AppColors.cardLight;
  Color get primary => AppColors.darkBrown;
  Color get accent => AppColors.premiumGold;
  Color get text => AppColors.darkText;
  Color get textSecondary => AppColors.caramelBeige;
  Color get surface => Colors.white;
  Color get error => const Color(0xFFB00020);
  Color get onPrimary => Colors.white;
  Color get onAccent => AppColors.darkBrown;
}

class DarkColors {
  const DarkColors();

  Color get background => AppColors.matteBlack;
  Color get card => AppColors.cardDark;
  Color get primary => AppColors.premiumGold;
  Color get accent => AppColors.premiumGold;
  Color get text => AppColors.lightText;
  Color get textSecondary => AppColors.caramelBeige;
  Color get surface => AppColors.secondaryBrown;
  Color get error => const Color(0xFFCF6679);
  Color get onPrimary => AppColors.darkBrown;
  Color get onAccent => AppColors.darkBrown;
}


