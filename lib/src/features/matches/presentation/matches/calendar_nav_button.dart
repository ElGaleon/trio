import 'package:flutter/material.dart';

import 'package:trio/theme/app_colors.dart';

class CalendarNavButton extends StatelessWidget {
  const CalendarNavButton({super.key, required this.icon, required this.onTap});

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
            color: AppColors.sportForeground(context).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.sportForeground(context).withValues(alpha: 0.12),
            ),
          ),
          child: Icon(
            icon,
            color: AppColors.sportForeground(context),
            size: 18,
          ),
        ),
      ),
    );
  }
}
