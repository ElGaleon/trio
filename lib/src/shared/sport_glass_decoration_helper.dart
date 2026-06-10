import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';

class GlassDecoration extends StatelessWidget {
  final Gradient? gradient;
  final double radius;
  final Widget? child;

  const GlassDecoration({
    super.key,
    this.gradient,
    this.radius = 28,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.07),
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.13)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.24),
              blurRadius: 28,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
