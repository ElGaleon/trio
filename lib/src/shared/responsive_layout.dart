import 'package:flutter/material.dart';

enum AppScreenSize { mobile, tablet, desktop }

class AppBreakpoints {
  const AppBreakpoints._();

  static const mobile = 0.0;
  static const tablet = 700.0;
  static const desktop = 1024.0;
  static const contentMaxWidth = 1120.0;
  static const loginShowcase = 760.0;

  static AppScreenSize fromWidth(double width) {
    if (width >= desktop) return AppScreenSize.desktop;
    if (width >= tablet) return AppScreenSize.tablet;
    return AppScreenSize.mobile;
  }

  static bool isMobileWidth(double width) =>
      fromWidth(width) == AppScreenSize.mobile;

  static bool isTabletWidth(double width) =>
      fromWidth(width) == AppScreenSize.tablet;

  static bool isDesktopWidth(double width) =>
      fromWidth(width) == AppScreenSize.desktop;

  static bool isWideWidth(double width) => width >= tablet;
}

class ResponsiveLayout {
  const ResponsiveLayout._();

  static const tablet = AppBreakpoints.tablet;
  static const desktop = AppBreakpoints.desktop;
  static const contentMaxWidth = AppBreakpoints.contentMaxWidth;

  static AppScreenSize screenSizeOf(BuildContext context) =>
      AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width);

  static bool isWide(BuildContext context) =>
      AppBreakpoints.isWideWidth(MediaQuery.sizeOf(context).width);

  static bool isMobile(BuildContext context) =>
      AppBreakpoints.isMobileWidth(MediaQuery.sizeOf(context).width);

  static bool isTablet(BuildContext context) =>
      AppBreakpoints.isTabletWidth(MediaQuery.sizeOf(context).width);

  static bool isDesktop(BuildContext context) =>
      AppBreakpoints.isDesktopWidth(MediaQuery.sizeOf(context).width);

  static int columnsFor(double width, {double minTileWidth = 320}) {
    return (width / minTileWidth).floor().clamp(1, 4);
  }

  static double horizontalPaddingFor(double width) {
    return switch (AppBreakpoints.fromWidth(width)) {
      AppScreenSize.desktop => 32,
      AppScreenSize.tablet => 24,
      AppScreenSize.mobile => 16,
    };
  }
}
