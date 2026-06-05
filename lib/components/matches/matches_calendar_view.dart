import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../app_router.dart';
import '../../model/scrimmage_match.dart';
import '../../providers/elo_providers.dart';
import '../../theme/app_colors.dart';
import '../shared/app_empty_state.dart';
import '../shared/match_card.dart';
import '../shared/sport_avatar_pill.dart';
import '../shared/sport_screen_shell.dart';

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
        _CalendarHeader(month: month, expanded: expanded),
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
                    axisAlignment: -1,
                    child: child,
                  ),
                );
              },
              child: expanded
                  ? _CalendarGrid(
                      key: const ValueKey('month-calendar'),
                      month: month,
                      matches: monthMatches,
                      selectedDay: selectedDay,
                      onSelect: (day) => _selectDay(ref, day),
                    )
                  : _CompactWeekCalendar(
                      key: const ValueKey('week-calendar'),
                      selectedDay: selectedDay ?? DateTime.now(),
                      matches: ref.watch(matchesProvider),
                      onSelect: (day) => _selectDay(ref, day),
                    ),
            ),
          ),
        ),
        _DayMatches(
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

class _CalendarHeader extends ConsumerWidget {
  const _CalendarHeader({required this.month, required this.expanded});

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
            _CalendarNavButton(
              icon: FIcons.chevronLeft,
              onTap: () => _move(ref, -1),
            ),
            Expanded(
              child: Column(
                spacing: 2,
                children: [
                  Text(
                    _monthLabel(month),
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
            _CalendarNavButton(
              icon: FIcons.chevronRight,
              onTap: () => _move(ref, 1),
            ),
            const SizedBox(width: 8),
            _CalendarNavButton(
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

class _CalendarNavButton extends StatelessWidget {
  const _CalendarNavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(icon, color: AppColors.white, size: 18),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
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
    final days = _calendarDays(month);
    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 8,
          children: [
            Row(
              children: [
                for (final day in ['L', 'M', 'M', 'G', 'V', 'S', 'D'])
                  Expanded(child: _WeekdayLabel(label: day)),
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
                    selectedDay != null && _sameDay(day, selectedDay!);
                return _CalendarDayCell(
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

class _CompactWeekCalendar extends StatelessWidget {
  const _CompactWeekCalendar({
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
    final start = selectedDay.subtract(
      Duration(days: selectedDay.weekday - DateTime.monday),
    );
    final days = [for (var i = 0; i < 7; i++) start.add(Duration(days: i))];
    final matchCounts = <String, int>{};
    for (final match in matches) {
      final key = _dayKey(match.createdAt);
      matchCounts.update(key, (value) => value + 1, ifAbsent: () => 1);
    }

    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          return _CompactDayCard(
            day: day,
            selected: _sameDay(day, selectedDay),
            matchCount: matchCounts[_dayKey(day)] ?? 0,
            onTap: () => onSelect(day),
          );
        },
      ),
    );
  }
}

class _CompactDayCard extends StatelessWidget {
  const _CompactDayCard({
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
        width: 66,
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
                right: 10,
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
                  Text(
                    day.day.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: selected ? AppColors.black : AppColors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  Text(
                    _weekdayShort(day),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: selected
                          ? AppColors.black.withValues(alpha: 0.70)
                          : sportMutedText,
                      fontWeight: FontWeight.w900,
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

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: sportMutedText,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
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
                color: inMonth ? AppColors.white : sportMutedText,
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

class _DayMatches extends StatelessWidget {
  const _DayMatches({
    required this.selectedDay,
    required this.matches,
    required this.onEdit,
    required this.onDelete,
  });

  final DateTime? selectedDay;
  final List<ScrimmageMatch> matches;
  final void Function(ScrimmageMatch match) onEdit;
  final void Function(ScrimmageMatch match) onDelete;

  @override
  Widget build(BuildContext context) {
    if (selectedDay == null) return const SizedBox.shrink();
    if (matches.isEmpty) {
      return SportEmptyState(
        icon: FIcons.calendarX,
        title: 'Nessun match',
        message: 'Non ci sono partite il ${_dayLabel(selectedDay!)}.',
      );
    }
    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            _dayLabel(selectedDay!),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        for (final match in matches)
          MatchCard(
            match: match,
            onTap: () => context.go(AppRoutes.matchDetail(match.id)),
            onEdit: () => onEdit(match),
            onDelete: () => onDelete(match),
          ),
      ],
    );
  }
}

List<DateTime> _calendarDays(DateTime month) {
  final first = DateTime(month.year, month.month);
  final firstOffset = first.weekday - DateTime.monday;
  final start = first.subtract(Duration(days: firstOffset));
  return [for (var i = 0; i < 42; i++) start.add(Duration(days: i))];
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _dayKey(DateTime date) {
  return '${date.year}-${date.month}-${date.day}';
}

String _weekdayShort(DateTime date) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[date.weekday - 1];
}

String _monthLabel(DateTime date) {
  const months = [
    'Gennaio',
    'Febbraio',
    'Marzo',
    'Aprile',
    'Maggio',
    'Giugno',
    'Luglio',
    'Agosto',
    'Settembre',
    'Ottobre',
    'Novembre',
    'Dicembre',
  ];
  return months[date.month - 1];
}

String _dayLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
