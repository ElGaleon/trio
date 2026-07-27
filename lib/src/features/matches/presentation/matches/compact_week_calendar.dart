import 'package:flutter/material.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'calendar_utils.dart';
import 'compact_day_card.dart';

class CompactWeekCalendar extends StatelessWidget {
  const CompactWeekCalendar({
    super.key,
    required this.selectedDay,
    required this.matches,
    required this.onSelect,
  });

  final DateTime selectedDay;
  final List<ScrimmageMatch> matches;
  final ValueChanged<DateTime> onSelect;

  @override
  Widget build(BuildContext context) {
    final start = selectedDay.subtract(const Duration(days: 3));
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final matchCounts = <String, int>{};
    for (final match in matches) {
      final key = CalendarUtils.dayKey(match.createdAt);
      matchCounts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    return SizedBox(
      height: 92,
      child: Row(
        spacing: 8,
        children: [
          for (final day in days)
            Expanded(
              child: CompactDayCard(
                day: day,
                selected: CalendarUtils.sameDay(day, selectedDay),
                matchCount: matchCounts[CalendarUtils.dayKey(day)] ?? 0,
                onTap: () => onSelect(day),
              ),
            ),
        ],
      ),
    );
  }
}
