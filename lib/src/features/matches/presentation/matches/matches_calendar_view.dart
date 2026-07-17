import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/application/matches_providers.dart';
import 'calendar_header.dart';
import 'calendar_grid.dart';
import 'compact_week_calendar.dart';
import 'day_matches.dart';

class MatchesCalendarView extends ConsumerWidget {
  const MatchesCalendarView({
    super.key,
    required this.onEdit,
    required this.onDelete,
  });

  final void Function(ScrimmageMatch match) onEdit;
  final void Function(ScrimmageMatch match) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(matchesCalendarMonthProvider);
    final expanded = ref.watch(matchesCalendarExpandedProvider);
    final monthMatches = ref.watch(calendarMonthMatchesProvider);
    final selectedDay = ref.watch(matchesCalendarSelectedDayProvider);
    final selectedMatches = ref.watch(selectedCalendarDayMatchesProvider);

    return Column(
      spacing: 14,
      children: [
        CalendarHeader(month: month, expanded: expanded),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (currentChild, previousChildren) {
                return Stack(
                  alignment: Alignment.topCenter,
                  children: [...previousChildren, ?currentChild],
                );
              },
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SizeTransition(
                    sizeFactor: curved,
                    alignment: Alignment.topLeft,
                    child: child,
                  ),
                );
              },
              child: expanded
                  ? CalendarGrid(
                      key: const ValueKey('month-calendar'),
                      month: month,
                      matches: monthMatches,
                      selectedDay: selectedDay,
                      onSelect: (day) => _selectDay(ref, day),
                    )
                  : CompactWeekCalendar(
                      key: const ValueKey('week-calendar'),
                      selectedDay: selectedDay ?? DateTime.now(),
                      matches: ref.watch(matchesProvider),
                      onSelect: (day) => _selectDay(ref, day),
                    ),
            ),
          ),
        ),
        DayMatches(
          selectedDay: selectedDay,
          matches: selectedMatches,
          onEdit: onEdit,
          onDelete: onDelete,
        ),
      ],
    );
  }

  void _selectDay(WidgetRef ref, DateTime day) {
    ref.read(matchesCalendarSelectedDayProvider.notifier).state = day;
    ref.read(matchesCalendarMonthProvider.notifier).state = DateTime(
      day.year,
      day.month,
    );
  }
}
