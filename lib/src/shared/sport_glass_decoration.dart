import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';

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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.24),
            blurRadius: blurRadius,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}
