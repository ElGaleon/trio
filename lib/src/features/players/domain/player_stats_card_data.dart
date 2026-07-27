import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/src/features/matches/domain/match_stat_event.dart';
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
    required this.pointsPlayed,
    required this.touchesPerPoint,
    required this.goalsPerPoint,
    required this.assistsPerPoint,
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
  final int pointsPlayed;
  final double touchesPerPoint;
  final double goalsPerPoint;
  final double assistsPerPoint;
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
      (match) => playerParticipatedInMatch(player.id, match),
    );
    var wins = 0;
    var losses = 0;
    for (final match in played) {
      if (match.isDraw) continue;
      final inTeamA =
          match.isExternalOpponent ||
          match.teamAIds.contains(player.id) ||
          match.teamARosterIds.contains(player.id) ||
          !match.teamBRosterIds.contains(player.id);
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
    final pointsPlayed = matches.fold<int>(0, (total, match) {
      return total +
          match.statEvents.where((event) {
            final pointEnded =
                event.type == MatchStatType.goal ||
                event.type == MatchStatType.opponentGoal;
            return pointEnded && event.lineupIds.contains(player.id);
          }).length;
    });
    final goals = matches.fold<int>(0, (total, match) {
      return total + _goalScorers(match).where((id) => id == player.id).length;
    });
    final assists = matches.fold<int>(0, (total, match) {
      return total + _assists(match).where((id) => id == player.id).length;
    });
    final touches = events
        .where(
          (e) =>
              e.type == MatchStatType.pass ||
              e.type == MatchStatType.huck ||
              e.type == MatchStatType.catchDisc ||
              e.type == MatchStatType.goal,
        )
        .length;
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
      goals: goals,
      assists: assists,
      defenses: events
          .where(
            (e) =>
                e.type == MatchStatType.defense ||
                e.type == MatchStatType.block,
          )
          .length,
      errors: events.where((e) => e.type.isError).length,
      touches: touches,
      pointsPlayed: pointsPlayed,
      touchesPerPoint: _ratio(touches, pointsPlayed),
      goalsPerPoint: _ratio(goals, pointsPlayed),
      assistsPerPoint: _ratio(assists, pointsPlayed),
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
        pointsPlayed: base.pointsPlayed,
        touchesPerPoint: base.touchesPerPoint,
        goalsPerPoint: base.goalsPerPoint,
        assistsPerPoint: base.assistsPerPoint,
        pulls: base.pulls,
        pullInRate: base.pullInRate,
        averagePullSeconds: base.averagePullSeconds,
      );

  final double value;

  @override
  double? get _cachedPlusMinus => value;
}

bool playerParticipatedInMatch(String playerId, ScrimmageMatch match) {
  return match.teamAIds.contains(playerId) ||
      match.teamBIds.contains(playerId) ||
      match.teamARosterIds.contains(playerId) ||
      match.teamBRosterIds.contains(playerId) ||
      match.presentPlayerIds.contains(playerId) ||
      match.statEvents.any(
        (event) =>
            event.playerId == playerId || event.lineupIds.contains(playerId),
      );
}

double _ratio(int numerator, int denominator) {
  return denominator == 0 ? 0 : numerator / denominator;
}

List<String> _goalScorers(ScrimmageMatch match) {
  final links = _passLinks(match);
  return match.statEvents
      .where((event) => event.type == MatchStatType.goal)
      .map((goal) {
        return goal.playerId ??
            links
                .where((link) => link.pointNumber == _scoredPoint(goal))
                .lastOrNull
                ?.receiverId;
      })
      .nonNulls
      .toList();
}

List<String> _assists(ScrimmageMatch match) {
  final links = _passLinks(match);
  return match.statEvents
      .where((event) => event.type == MatchStatType.goal)
      .map((goal) {
        return links
            .where((link) => link.pointNumber == _scoredPoint(goal))
            .lastOrNull
            ?.throwerId;
      })
      .nonNulls
      .toList();
}

List<_PassLink> _passLinks(ScrimmageMatch match) {
  final links = <_PassLink>[];
  String? holderId;
  for (final event in match.statEvents) {
    if (event.type == MatchStatType.goal ||
        event.type == MatchStatType.opponentGoal) {
      holderId = null;
      continue;
    }
    if (event.isCompletedPass && holderId != null && event.playerId != null) {
      links.add(
        _PassLink(
          pointNumber: event.pointNumber,
          throwerId: holderId,
          receiverId: event.playerId!,
        ),
      );
    }
    holderId = event.discHolderId;
  }
  return links;
}

int _scoredPoint(MatchStatEvent event) {
  return event.pointNumber > 1 ? event.pointNumber - 1 : event.pointNumber;
}

class _PassLink {
  const _PassLink({
    required this.pointNumber,
    required this.throwerId,
    required this.receiverId,
  });

  final int pointNumber;
  final String throwerId;
  final String receiverId;
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
