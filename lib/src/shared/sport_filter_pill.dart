import 'package:flutter/material.dart';
import 'package:trio/src/extensions/theme_extension.dart';
import 'package:trio/theme/app_colors.dart';

class SportFilterPill extends StatelessWidget {
  const SportFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final foreground = AppColors.sportForeground(context);
    final muted = AppColors.sportMutedForeground(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 32,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.24)
              : AppColors.sportGlass(context),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.sportBorder(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            if (icon != null)
              Icon(icon, color: selected ? foreground : muted, size: 16),
            Text(
              label,
              style: context.textTheme.bodySmall?.copyWith(
                color: selected ? foreground : muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
