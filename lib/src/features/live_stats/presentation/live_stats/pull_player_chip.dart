import 'package:flutter/material.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/players/domain/player.dart';

class PullPlayerChip extends StatelessWidget {
  const PullPlayerChip({
    super.key,
    required this.player,
    required this.selected,
    required this.onTap,
  });

  final Player player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.20)
              : AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          player.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
