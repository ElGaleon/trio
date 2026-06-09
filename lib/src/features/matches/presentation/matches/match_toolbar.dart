import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';

class MatchToolbar extends StatelessWidget {
  const MatchToolbar({
    super.key,
    required this.totalCount,
    required this.filteredCount,
    required this.hasFilters,
    required this.canCreate,
  });

  final int totalCount;
  final int filteredCount;
  final bool hasFilters;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            canCreate
                ? hasFilters
                    ? '$filteredCount di $totalCount partite'
                    : '$totalCount partite'
                : 'Servono almeno 6 giocatori',
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.sportMutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
