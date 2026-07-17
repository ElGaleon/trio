import 'package:trio/src/features/players/domain/player.dart';
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
          goals: events.where((e) => e.type == MatchStatType.goal).length,
          assists: events.where((e) => e.type == MatchStatType.assist).length,
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
}
