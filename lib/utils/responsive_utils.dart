import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints for different screen sizes
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Check if current screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  // Check if current screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  // Check if current screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }

  // Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(horizontal: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24);
    } else {
      return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  // Get responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.symmetric(vertical: 16);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(vertical: 24);
    } else {
      return const EdgeInsets.symmetric(vertical: 32);
    }
  }

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 16;
    } else if (isTablet(context)) {
      return 20;
    } else {
      return 24;
    }
  }

  // Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    if (isMobile(context)) {
      return baseFontSize;
    } else if (isTablet(context)) {
      return baseFontSize * 1.1;
    } else {
      return baseFontSize * 1.2;
    }
  }

  // Get responsive container width
  static double getResponsiveWidth(BuildContext context, double maxWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < maxWidth) {
      return screenWidth;
    }
    return maxWidth;
  }

  // Get responsive container constraints
  static BoxConstraints getResponsiveConstraints(
    BuildContext context,
    double maxWidth,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    return BoxConstraints(
      maxWidth: screenWidth < maxWidth ? screenWidth : maxWidth,
    );
  }

  // Get responsive grid columns
  static int getResponsiveColumns(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  // Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth - 32; // Full width minus padding
    } else if (isTablet(context)) {
      return (screenWidth - 48) / 2; // Half width minus padding
    } else {
      return (screenWidth - 64) / 3; // Third width minus padding
    }
  }

  // Get responsive button width
  static double? getResponsiveButtonWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity; // Full width on mobile
    } else {
      return null; // Auto width on tablet/desktop
    }
  }

  // Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.2;
    } else {
      return baseSize * 1.4;
    }
  }

  // Get responsive logo size
  static double getResponsiveLogoSize(BuildContext context) {
    if (isMobile(context)) {
      return 80;
    } else if (isTablet(context)) {
      return 100;
    } else {
      return 120;
    }
  }

  // Get responsive form width
  static double getResponsiveFormWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 400;
    } else {
      return 500;
    }
  }

  // Get responsive dialog width
  static double getResponsiveDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return screenWidth * 0.7;
    } else {
      return screenWidth * 0.5;
    }
  }

  // Get responsive bottom sheet height
  static double getResponsiveBottomSheetHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (isMobile(context)) {
      return screenHeight * 0.6;
    } else if (isTablet(context)) {
      return screenHeight * 0.5;
    } else {
      return screenHeight * 0.4;
    }
  }

  // Get responsive list item height
  static double getResponsiveListItemHeight(BuildContext context) {
    if (isMobile(context)) {
      return 80;
    } else if (isTablet(context)) {
      return 100;
    } else {
      return 120;
    }
  }

  // Get responsive image size
  static double getResponsiveImageSize(BuildContext context, double baseSize) {
    if (isMobile(context)) {
      return baseSize;
    } else if (isTablet(context)) {
      return baseSize * 1.3;
    } else {
      return baseSize * 1.6;
    }
  }

  // Get responsive border radius
  static double getResponsiveBorderRadius(
    BuildContext context,
    double baseRadius,
  ) {
    if (isMobile(context)) {
      return baseRadius;
    } else if (isTablet(context)) {
      return baseRadius * 1.2;
    } else {
      return baseRadius * 1.4;
    }
  }

  // Get responsive elevation
  static double getResponsiveElevation(
    BuildContext context,
    double baseElevation,
  ) {
    if (isMobile(context)) {
      return baseElevation;
    } else if (isTablet(context)) {
      return baseElevation * 1.2;
    } else {
      return baseElevation * 1.4;
    }
  }

  // Get responsive animation duration
  static Duration getResponsiveAnimationDuration(
    BuildContext context,
    Duration baseDuration,
  ) {
    if (isMobile(context)) {
      return baseDuration;
    } else if (isTablet(context)) {
      return Duration(
        milliseconds: (baseDuration.inMilliseconds * 1.1).round(),
      );
    } else {
      return Duration(
        milliseconds: (baseDuration.inMilliseconds * 1.2).round(),
      );
    }
  }

  // Get responsive text scale factor
  static double getResponsiveTextScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobileBreakpoint) {
      return 1.0;
    } else if (screenWidth < tabletBreakpoint) {
      return 1.1;
    } else {
      return 1.2;
    }
  }

  // Get responsive safe area padding
  static EdgeInsets getResponsiveSafeAreaPadding(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    if (isMobile(context)) {
      return padding;
    } else {
      return EdgeInsets.only(
        top: padding.top,
        bottom: padding.bottom,
        left: padding.left > 0 ? padding.left : 16,
        right: padding.right > 0 ? padding.right : 16,
      );
    }
  }

  // Get responsive orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Get responsive aspect ratio
  static double getResponsiveAspectRatio(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return size.width / size.height;
  }

  // Get responsive keyboard height
  static double getResponsiveKeyboardHeight(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom;
  }

  // Check if keyboard is visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  // Get responsive scroll physics
  static ScrollPhysics getResponsiveScrollPhysics(BuildContext context) {
    if (isMobile(context)) {
      return const BouncingScrollPhysics();
    } else {
      return const ClampingScrollPhysics();
    }
  }

  // Get responsive scroll behavior
  static ScrollBehavior getResponsiveScrollBehavior(BuildContext context) {
    if (isMobile(context)) {
      return const MaterialScrollBehavior();
    } else {
      return const ScrollBehavior();
    }
  }
}
