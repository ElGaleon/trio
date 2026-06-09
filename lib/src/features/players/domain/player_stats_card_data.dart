import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/match_stat_event.dart';
import 'player.dart';

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
    return PlayerStatsCardDataWithPlusMinus(this, value);
  }
}

class PlayerStatsCardDataWithPlusMinus extends PlayerStatsCardData {
  PlayerStatsCardDataWithPlusMinus(PlayerStatsCardData base, this.value)
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
