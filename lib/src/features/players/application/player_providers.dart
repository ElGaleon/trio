import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'package:skrim/src/features/players/domain/player_role.dart';
import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/matches/application/matches_providers.dart';
import 'package:skrim/src/features/settings/application/theme_mode_provider.dart';
import 'package:skrim/src/features/settings/domain/app_settings.dart';
import 'package:skrim/src/shared/state_provider.dart';

final appSettingsProvider = Provider<AppSettings>((ref) {
  final settings = ref.watch(firebaseSettingsProvider).value ?? AppSettings();
  return settings.copyWith(themeModeIndex: ref.watch(themeModeIndexProvider));
});

final playersProvider = Provider<List<Player>>((ref) {
  final players = ref.watch(firebasePlayersProvider).value ?? const [];
  return players;
});

final rankedPlayersProvider = Provider<List<Player>>((ref) {
  final players = [...ref.watch(playersProvider)];
  players.sort((first, second) => first.rating.compareTo(second.rating));
  return players;
});

final playersSearchQueryProvider = mutableProvider<String>(() => '');

final playersRoleFilterProvider = mutableProvider<PlayerRole?>(() => null);

final playersLineFilterProvider = mutableProvider<GameLine?>(() => null);

final filteredPlayersProvider = Provider<List<Player>>((ref) {
  return _filterPlayers(
    ref.watch(rankedPlayersProvider),
    ref.watch(playersSearchQueryProvider),
    ref.watch(playersRoleFilterProvider),
    ref.watch(playersLineFilterProvider),
  );
});

final rankingRoleFilterProvider = mutableProvider<PlayerRole?>(() => null);

final rankingLineFilterProvider = mutableProvider<GameLine?>(() => null);

final rankingStartDateFilterProvider = mutableProvider<DateTime?>(() => null);

final rankingEndDateFilterProvider = mutableProvider<DateTime?>(() => null);

final filteredRankingPlayersProvider = Provider<List<Player>>((ref) {
  final matches = ref.watch(matchesProvider);
  final rankedPlayers = ref.watch(rankedPlayersProvider);
  final startDate = ref.watch(rankingStartDateFilterProvider);
  final endDate = ref.watch(rankingEndDateFilterProvider);
  final roleFilter = ref.watch(rankingRoleFilterProvider);
  final lineFilter = ref.watch(rankingLineFilterProvider);
  final querySearch = ref.watch(playersSearchQueryProvider);
  final hasDateFilter = startDate != null || endDate != null;

  final filteredMatches = filterMatchesByDate(matches, startDate, endDate);

  return _filterPlayers(
    rankedPlayers,
    querySearch,
    roleFilter,
    lineFilter,
    hasDateFilter
        ? (player) => filteredMatches.any(
            (match) => match.containsPlayerById(player.id),
          )
        : null,
  );
});

List<Player> _filterPlayers(
  List<Player> players,
  String query,
  PlayerRole? role,
  GameLine? line, [
  bool Function(Player player)? extraFilter,
]) {
  final normalizedQuery = query.trim().toLowerCase();
  return players.where((player) {
    final matchesName =
        normalizedQuery.isEmpty ||
        player.name.toLowerCase().contains(normalizedQuery);
    final matchesRole = role == null || player.role == role;
    final matchesLine = line == null || player.linePreference == line;
    final matchesExtra = extraFilter == null || extraFilter(player);
    return matchesName && matchesRole && matchesLine && matchesExtra;
  }).toList();
}
