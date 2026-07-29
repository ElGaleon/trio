import 'package:flutter/foundation.dart';

class PlatformUtils {
  static bool get isMobile =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isWeb => kIsWeb;
}
