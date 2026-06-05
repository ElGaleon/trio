import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../app_constants.dart';
import '../model/app_settings.dart';
import '../model/player.dart';
import '../model/scrimmage_match.dart';
import '../repositories/elo_repository.dart';

class RecalculatedData {
  final List<Player> players;
  final List<ScrimmageMatch> matches;
  RecalculatedData(this.players, this.matches);
}

RecalculatedData recalculateRatingsInMemory({
  required List<Player> rawPlayers,
  required List<ScrimmageMatch> rawMatches,
  required AppSettings settings,
}) {
  final playersMap = {
    for (final player in rawPlayers)
      player.id: Player(
        id: player.id,
        name: player.name,
        rating: settings.initialRating,
        linePreference: player.linePreference,
        role: player.role,
        profileImagePath: player.profileImagePath,
        isExternal: player.isExternal,
      ),
  };

  final orderedMatches = rawMatches.map((match) {
    return ScrimmageMatch(
      id: match.id,
      createdAt: match.createdAt,
      teamAIds: List.from(match.teamAIds),
      teamBIds: List.from(match.teamBIds),
      scoreA: match.scoreA,
      scoreB: match.scoreB,
      teamSize: match.teamSize,
      offenseVsDefense: match.offenseVsDefense,
      teamAName: match.teamAName,
      teamBName: match.teamBName,
      isExternalOpponent: match.isExternalOpponent,
      division: match.division,
      tournament: match.tournament,
      matchType: match.matchType,
      windKmh: match.windKmh,
      pointsLimit: match.pointsLimit,
      durationMinutes: match.durationMinutes,
      location: match.location,
      hasHalfTime: match.hasHalfTime,
      halfTimeSeconds: match.halfTimeSeconds,
      hasTimeouts: match.hasTimeouts,
      timeoutsPerTeamPerHalf: match.timeoutsPerTeamPerHalf,
      timeoutSeconds: match.timeoutSeconds,
      enabledStatTypes: List.from(match.enabledStatTypes),
      statEvents: List.from(match.statEvents),
    );
  }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  for (final match in orderedMatches) {
    final teamA = match.teamAIds.map((id) => playersMap[id]).nonNulls.toList();
    final teamB = match.teamBIds.map((id) => playersMap[id]).nonNulls.toList();
    if (teamA.isEmpty ||
        teamB.isEmpty ||
        teamA.length < match.teamSize ||
        teamB.length < match.teamSize) {
      continue;
    }

    final allPlayers = [...teamA, ...teamB];
    final initialRatings = {
      for (final player in allPlayers) player.id: player.rating,
    };
    final ratingA =
        teamA.map((player) => player.rating).reduce((a, b) => a + b) /
        teamA.length;
    final ratingB =
        teamB.map((player) => player.rating).reduce((a, b) => a + b) /
        teamB.length;
    final expectedA = 1 / (1 + pow(10, (ratingB - ratingA) / 400));
    final expectedB = 1 - expectedA;
    final actualA = match.isDraw ? 0.5 : (match.teamAWon ? 1.0 : 0.0);
    final actualB = match.isDraw ? 0.5 : 1 - actualA;
    final deltaA = settings.eloKFactor * (actualA - expectedA);
    final deltaB = settings.eloKFactor * (actualB - expectedB);

    for (final player in teamA) {
      player
        ..rating += deltaA
        ..matchesPlayed += 1;
      if (!match.isDraw) {
        match.teamAWon ? player.wins += 1 : player.losses += 1;
      }
    }
    for (final player in teamB) {
      player
        ..rating += deltaB
        ..matchesPlayed += 1;
      if (!match.isDraw) {
        match.teamAWon ? player.losses += 1 : player.wins += 1;
      }
    }

    match
      ..initialRatings = initialRatings
      ..finalRatings = {
        for (final player in allPlayers) player.id: player.rating,
      };
  }

  return RecalculatedData(
    playersMap.values.toList(),
    orderedMatches,
  );
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final rawPlayersStreamProvider = StreamProvider<List<Player>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('players').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Player.fromMap(doc.data())).toList();
  });
});

final rawMatchesStreamProvider = StreamProvider<List<ScrimmageMatch>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('matches').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => ScrimmageMatch.fromMap(doc.data())).toList();
  });
});

final globalSettingsStreamProvider = StreamProvider<AppSettings>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('settings').doc('global').snapshots().map((doc) {
    if (!doc.exists || doc.data() == null) {
      return AppSettings();
    }
    return AppSettings.fromGlobalMap(doc.data()!);
  });
});

final settingsBoxProvider = Provider<Box<AppSettings>>((ref) {
  return Hive.box<AppSettings>(AppConstants.settingsBox);
});

final themeModeProvider = StateProvider<int>((ref) {
  final box = ref.watch(settingsBoxProvider);
  final settings = box.get(AppConstants.settingsKey);
  return settings?.themeModeIndex ?? 0;
});

final appSettingsProvider = Provider<AppSettings>((ref) {
  final localThemeIndex = ref.watch(themeModeProvider);
  final globalSettingsAsync = ref.watch(globalSettingsStreamProvider);
  final globalSettings = globalSettingsAsync.value ?? AppSettings();
  return globalSettings.copyWith(themeModeIndex: localThemeIndex);
});

final recalculatedDataProvider = Provider<RecalculatedData>((ref) {
  final rawPlayers = ref.watch(rawPlayersStreamProvider).value ?? [];
  final rawMatches = ref.watch(rawMatchesStreamProvider).value ?? [];
  final settings = ref.watch(appSettingsProvider);
  
  return recalculateRatingsInMemory(
    rawPlayers: rawPlayers,
    rawMatches: rawMatches,
    settings: settings,
  );
});

final rankedPlayersProvider = Provider<List<Player>>((ref) {
  final data = ref.watch(recalculatedDataProvider);
  return List.from(data.players)
    ..sort((a, b) => b.rating.compareTo(a.rating));
});

final matchesProvider = Provider<List<ScrimmageMatch>>((ref) {
  final data = ref.watch(recalculatedDataProvider);
  return List.from(data.matches)
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
});

final eloRepositoryProvider = Provider<EloRepository>((ref) {
  final matches = ref.watch(matchesProvider);
  final settings = ref.watch(appSettingsProvider);
  final firestore = ref.watch(firestoreProvider);
  return EloRepository(
    matches: matches,
    settings: settings,
    firestore: firestore,
  );
});

final hiveChangesProvider = StreamProvider<int>((ref) {
  final settingsBox = ref.watch(settingsBoxProvider);
  final controller = StreamController<int>();
  var tick = 0;

  void notify() {
    if (!controller.isClosed) controller.add(tick++);
  }

  final settingsListenable = settingsBox.listenable();
  settingsListenable.addListener(notify);
  Future.microtask(notify);

  ref.onDispose(() {
    settingsListenable.removeListener(notify);
    controller.close();
  });

  return controller.stream;
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

enum MatchesViewMode { list, calendar }

final matchesViewModeProvider = StateProvider<MatchesViewMode>(
  (ref) => MatchesViewMode.list,
);

final matchesCalendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final matchesCalendarSelectedDayProvider = StateProvider<DateTime?>(
  (ref) => DateTime.now(),
);

final matchesCalendarExpandedProvider = StateProvider<bool>((ref) => false);

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
