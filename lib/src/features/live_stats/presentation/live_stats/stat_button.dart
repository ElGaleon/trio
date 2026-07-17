import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';

class StatButton extends StatelessWidget {
  const StatButton({
    super.key,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (destructive ? AppColors.danger : AppColors.violet).withValues(
            alpha: 0.20,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive ? AppColors.danger : AppColors.violet,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
