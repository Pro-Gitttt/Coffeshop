import 'package:flutter/material.dart';

/// Responsive utility class for handling different screen sizes
class Responsive {
  /// Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  /// Get current screen width
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get current screen height
  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return screenWidth(context) < mobileBreakpoint;
  }

  /// Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return screenWidth(context) >= tabletBreakpoint;
  }

  /// Get responsive padding based on screen size
  static EdgeInsets responsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive horizontal padding
  static EdgeInsets responsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32.0);
    }
  }

  /// Get responsive font size
  static double responsiveFontSize(BuildContext context, {
    double mobile = 14,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.1;
    } else {
      return desktop ?? tablet ?? mobile * 1.2;
    }
  }

  /// Get responsive icon size
  static double responsiveIconSize(BuildContext context, {
    double mobile = 24,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.2;
    } else {
      return desktop ?? tablet ?? mobile * 1.4;
    }
  }

  /// Get responsive column count for grid layouts
  static int responsiveColumnCount(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? 2;
    } else {
      return desktop ?? tablet ?? 3;
    }
  }

  /// Get responsive max width for content containers
  static double responsiveMaxWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 800;
    } else {
      return 1200;
    }
  }

  /// Get responsive card width
  static double responsiveCardWidth(BuildContext context) {
    final width = screenWidth(context);
    if (isMobile(context)) {
      return width - 32;
    } else if (isTablet(context)) {
      return (width - 72) / 2;
    } else {
      return (width - 112) / 3;
    }
  }

  /// Center content with max width constraint
  static Widget responsiveContainer(BuildContext context, {required Widget child}) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: responsiveMaxWidth(context)),
        child: child,
      ),
    );
  }

  /// Get responsive spacing
  static double responsiveSpacing(BuildContext context, {
    double mobile = 8,
    double? tablet,
    double? desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.5;
    } else {
      return desktop ?? tablet ?? mobile * 2;
    }
  }
}

