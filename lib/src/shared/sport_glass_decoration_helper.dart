import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class GlassDecoration extends StatelessWidget {
  final Gradient? gradient;
  final double radius;
  final Widget? child;
  final Border? border;

  const GlassDecoration({
    super.key,
    this.gradient,
    this.radius = 28,
    this.child,
    this.border
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sportGlass(context),
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: border ?? Border.all(color: AppColors.sportBorder(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.07),
              blurRadius: isDark ? 28 : 18,
              offset: Offset(0, isDark ? 18 : 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
