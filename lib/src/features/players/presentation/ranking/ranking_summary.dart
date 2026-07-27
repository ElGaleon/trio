import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class RankingSummary extends StatelessWidget {
  const RankingSummary({
    super.key,
    required this.totalCount,
    required this.filteredCount,
    required this.hasFilters,
  });

  final int totalCount;
  final int filteredCount;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        hasFilters
            ? '$filteredCount di $totalCount giocatori'
            : '$totalCount giocatori',
        style: textTheme.bodySmall?.copyWith(
          color: AppColors.sportMutedForeground(context),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
