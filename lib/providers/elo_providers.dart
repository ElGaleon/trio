import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_constants.dart';
import '../models/app_settings.dart';
import '../models/player.dart';
import '../models/scrimmage_match.dart';
import '../repositories/elo_repository.dart';

final playersBoxProvider = Provider<Box<Player>>((ref) {
  return Hive.box<Player>(AppConstants.playersBox);
});

final matchesBoxProvider = Provider<Box<ScrimmageMatch>>((ref) {
  return Hive.box<ScrimmageMatch>(AppConstants.matchesBox);
});

final settingsBoxProvider = Provider<Box<AppSettings>>((ref) {
  return Hive.box<AppSettings>(AppConstants.settingsBox);
});

final appSettingsProvider = Provider<AppSettings>((ref) {
  ref.watch(hiveChangesProvider);
  return ref
          .watch(settingsBoxProvider)
          .get(AppConstants.settingsKey, defaultValue: AppSettings()) ??
      AppSettings();
});

final eloRepositoryProvider = Provider<EloRepository>((ref) {
  return EloRepository(
    ref.watch(playersBoxProvider),
    ref.watch(matchesBoxProvider),
    ref.watch(appSettingsProvider),
  );
});

final hiveChangesProvider = StreamProvider<int>((ref) {
  final playersBox = ref.watch(playersBoxProvider);
  final matchesBox = ref.watch(matchesBoxProvider);
  final settingsBox = ref.watch(settingsBoxProvider);
  final controller = StreamController<int>();
  var tick = 0;

  void notify() {
    if (!controller.isClosed) controller.add(tick++);
  }

  final playersListenable = playersBox.listenable();
  final matchesListenable = matchesBox.listenable();
  final settingsListenable = settingsBox.listenable();
  playersListenable.addListener(notify);
  matchesListenable.addListener(notify);
  settingsListenable.addListener(notify);
  Future.microtask(notify);

  ref.onDispose(() {
    playersListenable.removeListener(notify);
    matchesListenable.removeListener(notify);
    settingsListenable.removeListener(notify);
    controller.close();
  });

  return controller.stream;
});

final rankedPlayersProvider = Provider<List<Player>>((ref) {
  ref.watch(hiveChangesProvider);
  return ref.watch(eloRepositoryProvider).rankedPlayers;
});

final matchesProvider = Provider<List<ScrimmageMatch>>((ref) {
  ref.watch(hiveChangesProvider);
  return ref.watch(eloRepositoryProvider).matches;
});

final playersSearchQueryProvider = StateProvider<String>((ref) => '');

final playersRoleFilterProvider = StateProvider<PlayerRole?>((ref) => null);

final playersLineFilterProvider = StateProvider<PlayerLinePreference?>(
  (ref) => null,
);

final filteredPlayersProvider = Provider<List<Player>>((ref) {
  return _filterPlayers(
    ref.watch(rankedPlayersProvider),
    ref.watch(playersSearchQueryProvider),
    ref.watch(playersRoleFilterProvider),
    ref.watch(playersLineFilterProvider),
  );
});

final rankingRoleFilterProvider = StateProvider<PlayerRole?>((ref) => null);

final rankingLineFilterProvider = StateProvider<PlayerLinePreference?>(
  (ref) => null,
);

final filteredRankingPlayersProvider = Provider<List<Player>>((ref) {
  return _filterPlayers(
    ref.watch(rankedPlayersProvider),
    '',
    ref.watch(rankingRoleFilterProvider),
    ref.watch(rankingLineFilterProvider),
  );
});

final matchesStartDateFilterProvider = StateProvider<DateTime?>((ref) => null);

final matchesEndDateFilterProvider = StateProvider<DateTime?>((ref) => null);

final filteredMatchesProvider = Provider<List<ScrimmageMatch>>((ref) {
  final startDate = ref.watch(matchesStartDateFilterProvider);
  final endDate = ref.watch(matchesEndDateFilterProvider);
  final start = startDate == null
      ? null
      : DateTime(startDate.year, startDate.month, startDate.day);
  final end = endDate == null
      ? null
      : DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

  return ref.watch(matchesProvider).where((match) {
    final createdAt = match.createdAt;
    final afterStart = start == null || !createdAt.isBefore(start);
    final beforeEnd = end == null || !createdAt.isAfter(end);
    return afterStart && beforeEnd;
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

class RecentMatchTeam {
  const RecentMatchTeam({
    required this.name,
    required this.playerIds,
    required this.playerNames,
    required this.lastUsedAt,
  });

  final String name;
  final List<String> playerIds;
  final List<String> playerNames;
  final DateTime lastUsedAt;
}

List<Player> _filterPlayers(
  List<Player> players,
  String query,
  PlayerRole? role,
  PlayerLinePreference? line,
) {
  final normalizedQuery = query.trim().toLowerCase();
  return players.where((player) {
    final matchesName =
        normalizedQuery.isEmpty ||
        player.name.toLowerCase().contains(normalizedQuery);
    final matchesRole = role == null || player.role == role;
    final matchesLine = line == null || player.linePreference == line;
    return matchesName && matchesRole && matchesLine;
  }).toList();
}
