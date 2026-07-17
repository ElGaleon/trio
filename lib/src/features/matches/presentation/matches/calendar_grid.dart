import 'package:flutter/material.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'calendar_day_cell.dart';
import 'calendar_utils.dart';
import 'weekday_label.dart';

class CalendarGrid extends StatelessWidget {
  const CalendarGrid({
    super.key,
    required this.month,
    required this.matches,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime month;
  final List<ScrimmageMatch> matches;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final matchesByDay = <int, List<ScrimmageMatch>>{};
    for (final match in matches) {
      matchesByDay.putIfAbsent(match.createdAt.day, () => []).add(match);
    }
    final days = CalendarUtils.calendarDays(month);
    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 8,
          children: [
            Row(
              children: [
                for (final day in ['L', 'M', 'M', 'G', 'V', 'S', 'D'])
                  Expanded(child: WeekdayLabel(label: day)),
              ],
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final inMonth = day.month == month.month;
                final dayMatches = matchesByDay[day.day] ?? const [];
                final selected =
                    selectedDay != null &&
                    CalendarUtils.sameDay(day, selectedDay!);
                return CalendarDayCell(
                  day: day,
                  inMonth: inMonth,
                  selected: selected,
                  matchCount: inMonth ? dayMatches.length : 0,
                  onTap: inMonth ? () => onSelect(day) : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
