import 'package:flutter/material.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'calendar_utils.dart';

class CompactDayCard extends StatelessWidget {
  const CompactDayCard({
    super.key,
    required this.day,
    required this.selected,
    required this.matchCount,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final int matchCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 88,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.white.withValues(alpha: 0.94)
              : AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.13),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.24),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            if (matchCount > 0)
              Positioned(
                right: 8,
                top: 9,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.violet : AppColors.violetLight,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 5,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      day.day.toString(),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: selected ? AppColors.black : AppColors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      CalendarUtils.weekdayShort(day),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected
                            ? AppColors.black.withValues(alpha: 0.70)
                            : AppColors.sportMutedText,
                        fontWeight: FontWeight.w900,
                      ),
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
