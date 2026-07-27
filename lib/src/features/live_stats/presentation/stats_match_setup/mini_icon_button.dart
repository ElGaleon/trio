import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class MiniIconButton extends StatelessWidget {
  const MiniIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 32,
        height: 32,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.violet),
          ),
          child: Center(
            child: Icon(
              icon,
              color: AppColors.sportForeground(context),
              size: 15,
            ),
          ),
        ),
      ),
    );
  }
}
