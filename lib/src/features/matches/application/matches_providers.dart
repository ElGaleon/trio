import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'matches_view_mode.dart';
import 'recent_match_team.dart';
import 'package:skrim/src/shared/state_provider.dart';

final matchesProvider = Provider<List<ScrimmageMatch>>((ref) {
  return ref.watch(firebaseMatchesProvider).value ?? const [];
});

final matchesStartDateFilterProvider = mutableProvider<DateTime?>(() => null);

final matchesEndDateFilterProvider = mutableProvider<DateTime?>(() => null);

final matchesViewModeProvider = mutableProvider<MatchesViewMode>(
  () => MatchesViewMode.list,
);

final matchesCalendarMonthProvider = mutableProvider<DateTime>(() {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final matchesCalendarSelectedDayProvider = mutableProvider<DateTime?>(
  () => DateTime.now(),
);

final matchesCalendarExpandedProvider = mutableProvider<bool>(() => false);

final filteredMatchesProvider = Provider<List<ScrimmageMatch>>((ref) {
  return filterMatchesByDate(
    ref.watch(matchesProvider),
    ref.watch(matchesStartDateFilterProvider),
    ref.watch(matchesEndDateFilterProvider),
  );
});

List<ScrimmageMatch> filterMatchesByDate(
  List<ScrimmageMatch> matches,
  DateTime? startDate,
  DateTime? endDate,
) {
  final start = startDate == null
      ? null
      : DateTime(startDate.year, startDate.month, startDate.day);
  final end = endDate == null
      ? null
      : DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

  return matches.where((match) {
    final createdAt = match.createdAt;
    final afterStart = start == null || !createdAt.isBefore(start);
    final beforeEnd = end == null || !createdAt.isAfter(end);
    return afterStart && beforeEnd;
  }).toList();
}

final calendarMonthMatchesProvider = Provider<List<ScrimmageMatch>>((ref) {
  final month = ref.watch(matchesCalendarMonthProvider);
  final start = DateTime(month.year, month.month);
  final end = DateTime(month.year, month.month + 1);
  return ref.watch(matchesProvider).where((match) {
    return !match.createdAt.isBefore(start) && match.createdAt.isBefore(end);
  }).toList();
});

final selectedCalendarDayMatchesProvider = Provider<List<ScrimmageMatch>>((
  ref,
) {
  final selectedDay = ref.watch(matchesCalendarSelectedDayProvider);
  if (selectedDay == null) return const [];
  final start = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
  final end = start.add(const Duration(days: 1));
  return ref.watch(matchesProvider).where((match) {
    return !match.createdAt.isBefore(start) && match.createdAt.isBefore(end);
  }).toList();
});

final recentMatchTeamsProvider = Provider<List<RecentMatchTeam>>((ref) {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));
  final playersById = {
    for (final player in ref.watch(rankedPlayersProvider)) player.id: player,
  };
  final seen = <String>{};
  final teams = <RecentMatchTeam>[];

  final todayMatches = ref.watch(matchesProvider).where((match) {
    return !match.createdAt.isBefore(todayStart) &&
        match.createdAt.isBefore(tomorrowStart);
  }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void addTeam({
    required String name,
    required List<String> playerIds,
    required DateTime lastUsedAt,
  }) {
    if (playerIds.isEmpty) return;
    final knownIds = playerIds
        .where((id) => playersById.containsKey(id))
        .toList(growable: false);
    if (knownIds.length != playerIds.length) return;

    final signature = ([...knownIds]..sort()).join('|');
    if (!seen.add(signature)) return;

    teams.add(
      RecentMatchTeam(
        name: name,
        playerIds: knownIds,
        playerNames: [for (final id in knownIds) playersById[id]!.name],
        lastUsedAt: lastUsedAt,
      ),
    );
  }

  for (final match in todayMatches) {
    addTeam(
      name: match.teamAName,
      playerIds: match.teamAIds,
      lastUsedAt: match.createdAt,
    );
    addTeam(
      name: match.teamBName,
      playerIds: match.teamBIds,
      lastUsedAt: match.createdAt,
    );
    if (teams.length >= 8) break;
  }

  return teams.take(8).toList(growable: false);
});
