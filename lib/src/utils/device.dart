import 'package:flutter/widgets.dart';
import 'package:skrim/src/shared/responsive_layout.dart';

class DeviceUtils {
  const DeviceUtils._();

  static AppScreenSize screenSizeOf(BuildContext context) =>
      ResponsiveLayout.screenSizeOf(context);

  static bool isMobile(BuildContext context) =>
      ResponsiveLayout.isMobile(context);

  static bool isTablet(BuildContext context) =>
      ResponsiveLayout.isTablet(context);

  static bool isDesktop(BuildContext context) =>
      ResponsiveLayout.isDesktop(context);
}
