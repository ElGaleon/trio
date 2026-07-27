import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  AppColorPalette get appColors =>
      theme.extension<AppColorPalette>() ??
      AppColorPalette.forBrightness(theme.brightness);
}
