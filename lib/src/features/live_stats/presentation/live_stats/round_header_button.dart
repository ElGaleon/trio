import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class RoundHeaderButton extends StatelessWidget {
  const RoundHeaderButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.sportForeground(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.sportElevated(
              context,
            ).withValues(alpha: AppColors.isDark(context) ? 0.42 : 1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.sportBorder(context)),
          ),
          child: Center(child: Icon(icon, color: foreground, size: 20)),
        ),
      ),
    );
  }
}
