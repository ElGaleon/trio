import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';
import 'package:trio/src/features/players/domain/player_stats_card_data.dart';
import 'package:trio/src/features/players/domain/group_stats.dart';
import 'package:trio/src/features/players/domain/player_analytics.dart';
import 'package:trio/src/features/players/domain/player_detail_stats.dart';
import 'player_providers.dart';
import 'package:trio/src/features/matches/application/matches_providers.dart';
import 'package:trio/src/shared/state_provider.dart';

final statsSearchQueryProvider = mutableProvider<String>(() => '');

final statsRoleFilterProvider = mutableProvider<PlayerRole?>(() => null);

final statsLineFilterProvider = mutableProvider<PlayerLinePreference?>(
  () => null,
);

final selectedStatsPlayerIdProvider = mutableProvider<String?>(() => null);

final playerDetailTournamentFilterProvider =
    mutableProviderFamily<String?, String>((playerId) => null);

final playerDetailMatchFilterProvider = mutableProviderFamily<String?, String>(
  (playerId) => null,
);

final playerAnalyticsProvider = Provider<PlayerAnalytics>((ref) {
  final players = ref.watch(rankedPlayersProvider);
  final matches = ref.watch(matchesProvider);
  final query = ref.watch(statsSearchQueryProvider).trim().toLowerCase();
  final role = ref.watch(statsRoleFilterProvider);
  final line = ref.watch(statsLineFilterProvider);

  final filteredPlayers = players.where((player) {
    final matchesQuery =
        query.isEmpty || player.name.toLowerCase().contains(query);
    final matchesRole = role == null || player.role == role;
    final matchesLine = line == null || player.linePreference == line;
    return matchesQuery && matchesRole && matchesLine;
  }).toList();

  final playerIds = filteredPlayers.map((player) => player.id).toSet();
  final cards = [
    for (final player in filteredPlayers)
      PlayerStatsCardData.from(player, matches),
  ];

  return PlayerAnalytics(
    players: filteredPlayers,
    cards: cards,
    group: GroupStats.from(cards, matches, playerIds),
  );
});

final playerDetailStatsProvider = Provider.family<PlayerDetailStats?, String>((
  ref,
  playerId,
) {
  final player = ref
      .watch(rankedPlayersProvider)
      .where((item) => item.id == playerId)
      .firstOrNullCompat;
  if (player == null) return null;
  final allMatches = ref.watch(matchesProvider).where((match) {
    return match.teamAIds.contains(playerId) ||
        match.teamBIds.contains(playerId);
  }).toList();
  final tournaments =
      allMatches
          .map((match) => match.tournament.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  final tournament = ref.watch(playerDetailTournamentFilterProvider(playerId));
  final matchId = ref.watch(playerDetailMatchFilterProvider(playerId));
  final filtered = allMatches.where((match) {
    final matchesTournament =
        tournament == null || match.tournament.trim() == tournament;
    final matchesMatch = matchId == null || match.id == matchId;
    return matchesTournament && matchesMatch;
  }).toList();

  return PlayerDetailStats(
    matches: filtered,
    tournaments: tournaments,
    data: PlayerStatsCardData.from(player, filtered),
  );
});

extension _FirstOrNullCompat<T> on Iterable<T> {
  T? get firstOrNullCompat {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
