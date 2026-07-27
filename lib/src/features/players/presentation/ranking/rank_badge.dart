import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class RankBadge extends StatelessWidget {
  const RankBadge({
    super.key,
    required this.rank,
    required this.muted,
    required this.compact,
  });

  final int? rank;
  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 24.0 : 30.0;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: muted
              ? AppColors.white.withValues(alpha: 0.18)
              : rankColor(rank),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.sportBadgeBorder, width: 2),
        ),
        child: Center(
          child: Text(
            '${rank ?? '-'}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.sportForeground(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

Color rankColor(int? rank) {
  return switch (rank) {
    1 => AppColors.violet,
    2 => AppColors.violetMid,
    3 => AppColors.violetLight,
    _ => AppColors.sportMutedText,
  };
}
