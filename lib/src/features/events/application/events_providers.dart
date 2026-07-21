import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/events/domain/team_event.dart';
import 'package:trio/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:trio/src/features/matches/application/matches_providers.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/shared/state_provider.dart';

enum EventsViewMode { list, day, week, month }

extension EventsViewModeLabel on EventsViewMode {
  String get label => switch (this) {
    EventsViewMode.list => 'Lista',
    EventsViewMode.day => 'Giorno',
    EventsViewMode.week => 'Settimana',
    EventsViewMode.month => 'Mese',
  };
}

final eventsProvider = Provider<List<TeamEvent>>((ref) {
  return expandRecurringEvents(
    ref.watch(firebaseEventsProvider).value ?? const [],
  );
});

final eventsViewModeProvider = mutableProvider<EventsViewMode>(
  () => EventsViewMode.month,
);

final eventsSelectedDayProvider = mutableProvider<DateTime>(() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final selectedDayEventsProvider = Provider<List<TeamEvent>>((ref) {
  final day = ref.watch(eventsSelectedDayProvider);
  return eventsInRange(
    ref.watch(eventsProvider),
    DateTime(day.year, day.month, day.day),
    DateTime(day.year, day.month, day.day + 1),
  );
});

final activePlayableEventsProvider = Provider<List<TeamEvent>>((ref) {
  final now = DateTime.now();
  return ref.watch(eventsProvider).where((event) {
    final playable = event.type == TeamEventType.training || event.type.isMatch;
    return playable && event.startAt.isBefore(now) && event.endAt.isAfter(now);
  }).toList();
});

final eventMatchesProvider = Provider.family<List<ScrimmageMatch>, String>((
  ref,
  eventId,
) {
  return ref.watch(matchesProvider).where((match) {
    return match.eventId == eventId || match.trainingEventId == eventId;
  }).toList();
});

List<TeamEvent> eventsInRange(
  List<TeamEvent> events,
  DateTime start,
  DateTime end,
) {
  return events.where((event) {
    return event.startAt.isBefore(end) && event.endAt.isAfter(start);
  }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
}

List<TeamEvent> expandRecurringEvents(List<TeamEvent> events) {
  final now = DateTime.now();
  final horizonStart = DateTime(now.year - 1, now.month, now.day);
  final horizonEnd = DateTime(now.year + 2, now.month, now.day);
  final expanded = <TeamEvent>[];
  for (final event in events) {
    if (event.recurrence == TeamEventRecurrence.none) {
      expanded.add(event);
      continue;
    }
    final duration = event.endAt.difference(event.startAt);
    final recurrenceEndsAt = event.recurrenceEndsAt == null
        ? null
        : DateTime(
            event.recurrenceEndsAt!.year,
            event.recurrenceEndsAt!.month,
            event.recurrenceEndsAt!.day,
            23,
            59,
            59,
            999,
          );
    var startAt = event.startAt;
    while (startAt.isBefore(horizonEnd) &&
        (recurrenceEndsAt == null || !startAt.isAfter(recurrenceEndsAt))) {
      if (startAt.add(duration).isAfter(horizonStart)) {
        expanded.add(
          event.copyWith(
            id: '${event.id}#${startAt.millisecondsSinceEpoch}',
            startAt: startAt,
            endAt: startAt.add(duration),
            sourceEventId: event.id,
          ),
        );
      }
      startAt = switch (event.recurrence) {
        TeamEventRecurrence.weekly => startAt.add(const Duration(days: 7)),
        TeamEventRecurrence.monthly => _addMonths(startAt, 1),
        TeamEventRecurrence.none => horizonEnd,
      };
    }
  }
  return expanded..sort((a, b) => a.startAt.compareTo(b.startAt));
}

DateTime _addMonths(DateTime date, int months) {
  final target = DateTime(date.year, date.month + months);
  final lastDay = DateTime(target.year, target.month + 1, 0).day;
  return DateTime(
    target.year,
    target.month,
    date.day.clamp(1, lastDay),
    date.hour,
    date.minute,
  );
}

bool sameEventDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
