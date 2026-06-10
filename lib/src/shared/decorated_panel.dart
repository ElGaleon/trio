import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';

class DecoratedPanel extends StatelessWidget {
  final double radius;
  final Widget child;

  const DecoratedPanel({super.key, this.radius = 24, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sportHeaderDark,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.40),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}
