import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';

class RoundHeaderButton extends StatelessWidget {
  const RoundHeaderButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
          ),
          child: Center(child: Icon(icon, color: AppColors.white, size: 20)),
        ),
      ),
    );
  }
}
