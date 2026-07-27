import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:skrim/theme/app_colors.dart';

class RatingPill extends StatelessWidget {
  const RatingPill({super.key, required this.rating, this.emphasized = false});

  final int rating;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.violet.withValues(alpha: 0.18)
            : AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.sportForeground(context).withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            Icon(
              FIcons.sparkles,
              size: 13,
              color: emphasized ? AppColors.violet : AppColors.sportMutedText,
            ),
            Text(
              '$rating',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
