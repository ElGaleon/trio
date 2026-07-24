import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trio/theme/app_colors.dart';

class SystemOverlayStyleWrapper extends StatelessWidget {
  final Widget child;
  final Color statusBarColor;
  final Color? systemNavigationBarColor;
  final Color systemNavigationBarDividerColor;

  const SystemOverlayStyleWrapper({
    super.key,
    required this.child,
    this.statusBarColor = AppColors.transparent,
    this.systemNavigationBarColor,
    this.systemNavigationBarDividerColor = AppColors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: statusBarColor,
            systemNavigationBarColor:
                systemNavigationBarColor ?? AppColors.pageBackground(context),
            systemNavigationBarDividerColor: systemNavigationBarDividerColor,
          ),
      child: Scaffold(body: child),
    );
  }
}
