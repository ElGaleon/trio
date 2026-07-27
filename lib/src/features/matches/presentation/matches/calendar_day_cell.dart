import 'package:flutter/material.dart';
import 'package:skrim/theme/app_colors.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.day,
    required this.inMonth,
    required this.selected,
    required this.matchCount,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool selected;
  final int matchCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.24)
              : AppColors.white.withValues(alpha: inMonth ? 0.06 : 0.025),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            Text(
              day.day.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: inMonth ? AppColors.white : AppColors.sportMutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(
              height: 5,
              child: matchCount == 0
                  ? null
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        for (var i = 0; i < matchCount.clamp(1, 3); i++)
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.violetLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
