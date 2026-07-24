import 'package:flutter/material.dart';
import 'package:trio/theme/app_colors.dart';

class SportGlassDecoration extends StatelessWidget {
  final Gradient? gradient;
  final double radius;
  final double blurRadius;
  final Widget child;

  const SportGlassDecoration({
    super.key,
    this.gradient,
    this.radius = 20,
    this.blurRadius = 28,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sportGlass(context),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.sportBorder(context)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: isDark ? 0.24 : 0.07),
            blurRadius: isDark ? blurRadius : 18,
            offset: Offset(0, isDark ? 18 : 10),
          ),
        ],
      ),
      child: child,
    );
  }
}
