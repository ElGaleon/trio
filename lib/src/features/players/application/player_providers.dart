import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';
import 'package:trio/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:trio/src/features/matches/application/matches_providers.dart';
import 'package:trio/src/features/settings/application/theme_mode_provider.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';
import 'package:trio/src/shared/state_provider.dart';

final appSettingsProvider = Provider<AppSettings>((ref) {
  final settings = ref.watch(firebaseSettingsProvider).value ?? AppSettings();
  return settings.copyWith(themeModeIndex: ref.watch(themeModeIndexProvider));
});

final rankedPlayersProvider = Provider<List<Player>>((ref) {
  return ref.watch(firebasePlayersProvider).value ?? const [];
});

final playersSearchQueryProvider = mutableProvider<String>(() => '');

final playersRoleFilterProvider = mutableProvider<PlayerRole?>(() => null);

final playersLineFilterProvider = mutableProvider<PlayerLinePreference?>(
  () => null,
);

final filteredPlayersProvider = Provider<List<Player>>((ref) {
  return _filterPlayers(
    ref.watch(rankedPlayersProvider),
    ref.watch(playersSearchQueryProvider),
    ref.watch(playersRoleFilterProvider),
    ref.watch(playersLineFilterProvider),
  );
});

final rankingRoleFilterProvider = mutableProvider<PlayerRole?>(() => null);

final rankingLineFilterProvider = mutableProvider<PlayerLinePreference?>(
  () => null,
);

final rankingStartDateFilterProvider = mutableProvider<DateTime?>(() => null);

final rankingEndDateFilterProvider = mutableProvider<DateTime?>(() => null);

final filteredRankingPlayersProvider = Provider<List<Player>>((ref) {
  final startDate = ref.watch(rankingStartDateFilterProvider);
  final endDate = ref.watch(rankingEndDateFilterProvider);
  final hasDateFilter = startDate != null || endDate != null;
  final matches = filterMatchesByDate(
    ref.watch(matchesProvider),
    startDate,
    endDate,
  );

  return _filterPlayers(
    ref.watch(rankedPlayersProvider),
    '',
    ref.watch(rankingRoleFilterProvider),
    ref.watch(rankingLineFilterProvider),
    hasDateFilter
        ? (player) => matches.any((match) {
            return match.teamAIds.contains(player.id) ||
                match.teamBIds.contains(player.id) ||
                match.teamARosterIds.contains(player.id) ||
                match.teamBRosterIds.contains(player.id) ||
                match.presentPlayerIds.contains(player.id) ||
                match.statEvents.any(
                  (event) =>
                      event.playerId == player.id ||
                      event.lineupIds.contains(player.id),
                );
          })
        : null,
  );
});

List<Player> _filterPlayers(
  List<Player> players,
  String query,
  PlayerRole? role,
  PlayerLinePreference? line, [
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
