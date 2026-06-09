import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/common_widgets/sport_glass_decoration_helper.dart';
import 'package:trio/src/common_widgets/sport_screen_shell.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/presentation/matches/calendar_utils.dart';
import 'package:trio/src/features/matches/presentation/matches/calendar_nav_button.dart';
import 'package:trio/src/features/matches/application/matches_providers.dart';

class CalendarHeader extends ConsumerWidget {
  const CalendarHeader({super.key, required this.month, required this.expanded});

  final DateTime month;
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            CalendarNavButton(
              icon: FIcons.chevronLeft,
              onTap: () => _move(ref, -1),
            ),
            Expanded(
              child: Column(
                spacing: 2,
                children: [
                  Text(
                    CalendarUtils.monthLabel(month),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    month.year.toString(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: sportMutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            CalendarNavButton(
              icon: FIcons.chevronRight,
              onTap: () => _move(ref, 1),
            ),
            const SizedBox(width: 8),
            CalendarNavButton(
              icon: expanded ? FIcons.chevronUp : FIcons.chevronDown,
              onTap: () =>
                  ref.read(matchesCalendarExpandedProvider.notifier).state =
                      !expanded,
            ),
          ],
        ),
      ),
    );
  }

  void _move(WidgetRef ref, int direction) {
    if (expanded) {
      final nextMonth = DateTime(month.year, month.month + direction);
      ref.read(matchesCalendarMonthProvider.notifier).state = nextMonth;
      ref.read(matchesCalendarSelectedDayProvider.notifier).state = nextMonth;
      return;
    }

    final current =
        ref.read(matchesCalendarSelectedDayProvider) ?? DateTime.now();
    final nextDay = current.add(Duration(days: direction * 7));
    ref.read(matchesCalendarSelectedDayProvider.notifier).state = nextDay;
    ref.read(matchesCalendarMonthProvider.notifier).state = DateTime(
      nextDay.year,
      nextDay.month,
    );
  }
}
