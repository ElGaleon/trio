import 'package:flutter/material.dart';
import 'package:trio/theme/app_colors.dart';

class TeamTabHeader extends StatelessWidget {
  const TeamTabHeader({
    super.key,
    required this.label,
    required this.selected,
    required this.count,
    required this.teamSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final int count;
  final int teamSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.20)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          spacing: 8,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.white : AppColors.sportMutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: count == teamSize
                    ? AppColors.violetLight.withValues(alpha: 0.3)
                    : AppColors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count/$teamSize',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: count == teamSize
                      ? AppColors.violetLight
                      : AppColors.sportMutedText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
