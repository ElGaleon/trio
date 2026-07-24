import 'package:flutter/material.dart';
import 'package:trio/theme/app_colors.dart';

class DecoratedPanel extends StatelessWidget {
  final double radius;
  final Widget child;

  const DecoratedPanel({super.key, this.radius = 24, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = AppColors.isDark(context);
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sportSurface(context),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.sportBorder(context)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: isDark ? 0.40 : 0.08),
              blurRadius: isDark ? 28 : 18,
              offset: Offset(0, isDark ? 16 : 10),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
