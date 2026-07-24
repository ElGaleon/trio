import 'package:trio/src/features/players/domain/player.dart';
import 'match_stat_event.dart';
import 'scrimmage_match.dart';
import 'match_stat_type.dart';

class IndividualStatLine {
  const IndividualStatLine({
    required this.player,
    required this.goals,
    required this.assists,
    required this.touches,
    required this.defenses,
    required this.errors,
    required this.pointsPlayed,
  });

  final Player player;
  final int goals;
  final int assists;
  final int touches;
  final int defenses;
  final int errors;
  final int pointsPlayed;

  double get touchesPerPoint => _ratio(touches, pointsPlayed);
  double get goalsPerPoint => _ratio(goals, pointsPlayed);
  double get assistsPerPoint => _ratio(assists, pointsPlayed);

  double get rating {
    return 6 +
        (goals * 0.9) +
        (assists * 0.6) +
        (defenses * 0.7) +
        (touches * 0.08) -
        (errors * 0.45) +
        (pointsPlayed * 0.05);
  }

  static List<IndividualStatLine> from(
    ScrimmageMatch match,
    Map<String, Player> playersById,
  ) {
    final passLinks = _passLinks(match);
    final goalScorers = _goalScorers(match, passLinks);
    final assists = _assists(match, passLinks);
    final ids = <String>{...match.teamAIds};
    for (final event in match.statEvents) {
      if (event.playerId != null) ids.add(event.playerId!);
      ids.addAll(event.lineupIds);
    }
    final rows = <IndividualStatLine>[];
    for (final id in ids) {
      final player = playersById[id];
      if (player == null) continue;
      final events = match.statEvents.where((event) => event.playerId == id);
      final pointsPlayed = match.statEvents.where((event) {
        final pointEnded =
            event.type == MatchStatType.goal ||
            event.type == MatchStatType.opponentGoal;
        return pointEnded && event.lineupIds.contains(id);
      }).length;
      rows.add(
        IndividualStatLine(
          player: player,
          goals: goalScorers.where((scorerId) => scorerId == id).length,
          assists: assists.where((assistantId) => assistantId == id).length,
          touches: events
              .where(
                (e) =>
                    e.type == MatchStatType.pass ||
                    e.type == MatchStatType.huck ||
                    e.type == MatchStatType.catchDisc ||
                    e.type == MatchStatType.goal,
              )
              .length,
          defenses: events
              .where(
                (e) =>
                    e.type == MatchStatType.defense ||
                    e.type == MatchStatType.block,
              )
              .length,
          errors: events.where((e) => e.type.isError).length,
          pointsPlayed: pointsPlayed,
        ),
      );
    }
    rows.sort((a, b) => b.rating.compareTo(a.rating));
    return rows;
  }

  static double _ratio(int numerator, int denominator) {
    return denominator == 0 ? 0 : numerator / denominator;
  }

  static List<_PassLink> _passLinks(ScrimmageMatch match) {
    final links = <_PassLink>[];
    String? holderId;
    for (final event in match.statEvents) {
      if (_endsPoint(event.type)) {
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

  static List<String> _goalScorers(
    ScrimmageMatch match,
    List<_PassLink> passLinks,
  ) {
    return match.statEvents
        .where((event) => event.type == MatchStatType.goal)
        .map((goal) {
          return goal.playerId ??
              passLinks
                  .where((link) => link.pointNumber == _scoredPoint(goal))
                  .lastOrNull
                  ?.receiverId;
        })
        .nonNulls
        .toList();
  }

  static List<String> _assists(
    ScrimmageMatch match,
    List<_PassLink> passLinks,
  ) {
    return match.statEvents
        .where((event) => event.type == MatchStatType.goal)
        .map((goal) {
          return passLinks
              .where((link) => link.pointNumber == _scoredPoint(goal))
              .lastOrNull
              ?.throwerId;
        })
        .nonNulls
        .toList();
  }

  static int _scoredPoint(MatchStatEvent event) {
    return event.pointNumber > 1 ? event.pointNumber - 1 : event.pointNumber;
  }

  static bool _endsPoint(MatchStatType type) {
    return type == MatchStatType.goal || type == MatchStatType.opponentGoal;
  }
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
