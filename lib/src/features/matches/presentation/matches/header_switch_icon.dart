import 'package:flutter/material.dart';
import 'package:trio/theme/app_colors.dart';

class HeaderSwitchIcon extends StatelessWidget {
  const HeaderSwitchIcon({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.85)
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.sportForeground(context), size: 17),
      ),
    );
  }
}
