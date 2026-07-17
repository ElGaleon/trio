import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:trio/src/constants/app_constants.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/data/elo_repository.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';
import 'package:flutter_riverpod/legacy.dart';

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
