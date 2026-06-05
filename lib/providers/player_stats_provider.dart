import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/player.dart';
import '../model/scrimmage_match.dart';
import 'elo_providers.dart';

final statsSearchQueryProvider = StateProvider<String>((ref) => '');

final statsRoleFilterProvider = StateProvider<PlayerRole?>((ref) => null);

final statsLineFilterProvider = StateProvider<PlayerLinePreference?>(
  (ref) => null,
);

final selectedStatsPlayerIdProvider = StateProvider<String?>((ref) => null);

final playerDetailTournamentFilterProvider =
    StateProvider.family<String?, String>((ref, playerId) => null);

final playerDetailMatchFilterProvider = StateProvider.family<String?, String>(
  (ref, playerId) => null,
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

class PlayerAnalytics {
  const PlayerAnalytics({
    required this.players,
    required this.cards,
    required this.group,
  });

  final List<Player> players;
  final List<PlayerStatsCardData> cards;
  final GroupStats group;

  PlayerStatsCardData? byId(String? playerId) {
    if (playerId == null) return _firstOrNull(cards);
    return _firstOrNull(cards.where((card) => card.player.id == playerId)) ??
        _firstOrNull(cards);
  }
}

T? _firstOrNull<T>(Iterable<T> values) {
  final iterator = values.iterator;
  return iterator.moveNext() ? iterator.current : null;
}

class GroupStats {
  const GroupStats({
    required this.playerCount,
    required this.matches,
    required this.averageRating,
    required this.averageWinRate,
    required this.goals,
    required this.assists,
    required this.defenses,
    required this.errors,
    required this.pulls,
    required this.pullInRate,
  });

  final int playerCount;
  final int matches;
  final double averageRating;
  final double averageWinRate;
  final int goals;
  final int assists;
  final int defenses;
  final int errors;
  final int pulls;
  final double pullInRate;

  static GroupStats from(
    List<PlayerStatsCardData> cards,
    List<ScrimmageMatch> matches,
    Set<String> playerIds,
  ) {
    final filteredEvents = matches.expand((match) {
      return match.statEvents.where((event) {
        final id = event.playerId;
        return id != null && playerIds.contains(id);
      });
    }).toList();
    final pulls = filteredEvents.where((e) => e.type == MatchStatType.pull);
    final pullCount = pulls.length;
    final inBounds = pulls.where((e) => e.pullInBounds == true).length;

    return GroupStats(
      playerCount: cards.length,
      matches: cards.fold(0, (total, card) => total + card.matchesPlayed),
      averageRating: cards.isEmpty
          ? 0
          : cards.fold<double>(0, (total, card) => total + card.player.rating) /
                cards.length,
      averageWinRate: cards.isEmpty
          ? 0
          : cards.fold<double>(0, (total, card) => total + card.winRate) /
                cards.length,
      goals: filteredEvents.where((e) => e.type == MatchStatType.goal).length,
      assists: filteredEvents
          .where((e) => e.type == MatchStatType.assist)
          .length,
      defenses: filteredEvents
          .where(
            (e) =>
                e.type == MatchStatType.defense ||
                e.type == MatchStatType.block,
          )
          .length,
      errors: filteredEvents.where((e) => e.type.isError).length,
      pulls: pullCount,
      pullInRate: pullCount == 0 ? 0 : inBounds / pullCount,
    );
  }
}

class PlayerStatsCardData {
  const PlayerStatsCardData({
    required this.player,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.goals,
    required this.assists,
    required this.defenses,
    required this.errors,
    required this.touches,
    required this.pulls,
    required this.pullInRate,
    required this.averagePullSeconds,
  });

  final Player player;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int goals;
  final int assists;
  final int defenses;
  final int errors;
  final int touches;
  final int pulls;
  final double pullInRate;
  final double averagePullSeconds;

  double get winRate => matchesPlayed == 0 ? 0 : wins / matchesPlayed;
  double get impactScore => plusMinus;
  double get plusMinus => _plusMinus;

  double get _plusMinus {
    return _cachedPlusMinus ?? 0;
  }

  double? get _cachedPlusMinus => null;

  static PlayerStatsCardData from(Player player, List<ScrimmageMatch> matches) {
    final played = matches.where(
      (match) =>
          match.teamAIds.contains(player.id) ||
          match.teamBIds.contains(player.id),
    );
    var wins = 0;
    var losses = 0;
    for (final match in played) {
      if (match.isDraw) continue;
      final inTeamA = match.teamAIds.contains(player.id);
      final won = inTeamA == match.teamAWon;
      if (won) {
        wins++;
      } else {
        losses++;
      }
    }

    final events = matches.expand((match) {
      return match.statEvents.where((event) => event.playerId == player.id);
    }).toList();
    final pulls = events.where((event) => event.type == MatchStatType.pull);
    final pullList = pulls.toList();
    final pullDurations = pullList
        .map((event) => event.pullDurationSeconds)
        .whereType<int>()
        .toList();

    return PlayerStatsCardData(
      player: player,
      matchesPlayed: played.length,
      wins: wins,
      losses: losses,
      goals: events.where((e) => e.type == MatchStatType.goal).length,
      assists: events.where((e) => e.type == MatchStatType.assist).length,
      defenses: events
          .where(
            (e) =>
                e.type == MatchStatType.defense ||
                e.type == MatchStatType.block,
          )
          .length,
      errors: events.where((e) => e.type.isError).length,
      touches: events
          .where(
            (e) =>
                e.type == MatchStatType.pass ||
                e.type == MatchStatType.huck ||
                e.type == MatchStatType.catchDisc ||
                e.type == MatchStatType.goal,
          )
          .length,
      pulls: pullList.length,
      pullInRate: pullList.isEmpty
          ? 0
          : pullList.where((e) => e.pullInBounds == true).length /
                pullList.length,
      averagePullSeconds: pullDurations.isEmpty
          ? 0
          : pullDurations.reduce((a, b) => a + b) / pullDurations.length,
    ).withPlusMinus(_sumEventValues(events));
  }

  PlayerStatsCardData withPlusMinus(double value) {
    return _PlayerStatsCardDataWithPlusMinus(this, value);
  }
}

class _PlayerStatsCardDataWithPlusMinus extends PlayerStatsCardData {
  _PlayerStatsCardDataWithPlusMinus(PlayerStatsCardData base, this.value)
    : super(
        player: base.player,
        matchesPlayed: base.matchesPlayed,
        wins: base.wins,
        losses: base.losses,
        goals: base.goals,
        assists: base.assists,
        defenses: base.defenses,
        errors: base.errors,
        touches: base.touches,
        pulls: base.pulls,
        pullInRate: base.pullInRate,
        averagePullSeconds: base.averagePullSeconds,
      );

  final double value;

  @override
  double? get _cachedPlusMinus => value;
}

double _sumEventValues(Iterable<MatchStatEvent> events) {
  return events.fold<double>(0, (total, event) {
    return total + (event.statValue ?? _defaultValueFor(event.type));
  });
}

double _defaultValueFor(MatchStatType type) {
  return switch (type) {
    MatchStatType.goal => 3,
    MatchStatType.assist => 2,
    MatchStatType.defense || MatchStatType.block => 2,
    MatchStatType.pass || MatchStatType.catchDisc => 0.2,
    MatchStatType.huck => 0.4,
    MatchStatType.pull => 0.8,
    MatchStatType.opponentError => 0.5,
    MatchStatType.throwError || MatchStatType.stallOut => -2,
    MatchStatType.catchError => -1.5,
    MatchStatType.openError ||
    MatchStatType.deepError ||
    MatchStatType.resetError ||
    MatchStatType.opponentGoal => -1,
    _ => 0,
  };
}

class PlayerDetailStats {
  const PlayerDetailStats({
    required this.matches,
    required this.tournaments,
    required this.data,
  });

  final List<ScrimmageMatch> matches;
  final List<String> tournaments;
  final PlayerStatsCardData data;
}

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
