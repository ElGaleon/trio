import 'player.dart';
import 'scrimmage_match.dart';

class NamedCount {
  const NamedCount(this.name, this.value);

  final String name;
  final int value;
}

class FinalStatsSummary {
  const FinalStatsSummary({
    required this.goals,
    required this.turnovers,
    required this.breaks,
    required this.passAccuracy,
    required this.oLineEffectiveness,
    required this.oLineEfficiency,
    required this.dLineTurnoverRatio,
    required this.dLineConversionRatio,
    required this.topScorer,
    required this.mostAssist,
    required this.mostTouches,
    required this.bestDefender,
    required this.mostPlayed,
    required this.pointsPlayed,
  });

  final int goals;
  final int turnovers;
  final int breaks;
  final double passAccuracy;
  final double oLineEffectiveness;
  final double oLineEfficiency;
  final double dLineTurnoverRatio;
  final double dLineConversionRatio;
  final String topScorer;
  final String mostAssist;
  final String mostTouches;
  final String bestDefender;
  final String mostPlayed;
  final List<NamedCount> pointsPlayed;

  static FinalStatsSummary from(
    ScrimmageMatch match,
    Map<String, Player> playersById,
  ) {
    final events = match.statEvents;
    final goals = events.where((e) => e.type == MatchStatType.goal).length;
    final turnovers = events.where((e) => e.type.isError).length;
    final completedPasses = events
        .where(
          (e) => e.type == MatchStatType.pass || e.type == MatchStatType.huck,
        )
        .length;
    final attemptedPasses =
        completedPasses +
        events
            .where(
              (e) =>
                  e.type == MatchStatType.throwError ||
                  e.type == MatchStatType.catchError,
            )
            .length;

    final pointStarts = <int, bool>{};
    for (final event in events) {
      pointStarts.putIfAbsent(event.pointNumber, () => event.oursOnOffense);
    }
    final ourGoalEvents = events.where((e) => e.type == MatchStatType.goal);
    final breaks = ourGoalEvents
        .where((event) => pointStarts[event.pointNumber] == false)
        .length;
    final oLineStarts = pointStarts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    final dLineStarts = pointStarts.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toSet();
    final oLineGoals = ourGoalEvents
        .where((event) => oLineStarts.contains(event.pointNumber))
        .length;
    final oLineCleanGoals = ourGoalEvents.where((goal) {
      if (!oLineStarts.contains(goal.pointNumber)) return false;
      return !events.any(
        (event) => event.pointNumber == goal.pointNumber && event.type.isError,
      );
    }).length;
    final dLineTurnovers = dLineStarts.where((point) {
      return events.any(
        (event) =>
            event.pointNumber == point &&
            (event.type == MatchStatType.opponentError ||
                event.type == MatchStatType.block ||
                event.type == MatchStatType.defense),
      );
    }).length;
    final dLineGoals = ourGoalEvents
        .where((event) => dLineStarts.contains(event.pointNumber))
        .length;

    final playerGoals = _countByPlayer(events, {
      MatchStatType.goal,
    }, playersById);
    final playerAssists = _countByPlayer(events, {
      MatchStatType.assist,
    }, playersById);
    final playerTouches = _countByPlayer(events, {
      MatchStatType.pass,
      MatchStatType.huck,
      MatchStatType.catchDisc,
      MatchStatType.goal,
    }, playersById);
    final playerDefenses = _countByPlayer(events, {
      MatchStatType.defense,
      MatchStatType.block,
    }, playersById);
    final playedCounts = <String, int>{};
    for (final event in events.where(
      (e) =>
          e.type == MatchStatType.goal || e.type == MatchStatType.opponentGoal,
    )) {
      for (final id in event.lineupIds) {
        playedCounts.update(id, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final pointsPlayed =
        playedCounts.entries
            .map(
              (entry) => NamedCount(
                playersById[entry.key]?.name ?? 'Giocatore',
                entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return FinalStatsSummary(
      goals: goals,
      turnovers: turnovers,
      breaks: breaks,
      passAccuracy: _ratio(completedPasses, attemptedPasses),
      oLineEffectiveness: _ratio(oLineGoals, oLineStarts.length),
      oLineEfficiency: _ratio(oLineCleanGoals, oLineGoals),
      dLineTurnoverRatio: _ratio(dLineTurnovers, dLineStarts.length),
      dLineConversionRatio: _ratio(dLineGoals, dLineStarts.length),
      topScorer: _leader(playerGoals),
      mostAssist: _leader(playerAssists),
      mostTouches: _leader(playerTouches),
      bestDefender: _leader(playerDefenses),
      mostPlayed: pointsPlayed.isEmpty
          ? '-'
          : '${pointsPlayed.first.name} (${pointsPlayed.first.value})',
      pointsPlayed: pointsPlayed,
    );
  }

  String percent(double value) => '${(value * 100).round()}%';

  static double _ratio(int numerator, int denominator) {
    return denominator == 0 ? 0 : numerator / denominator;
  }

  static Map<String, int> _countByPlayer(
    Iterable<MatchStatEvent> events,
    Set<MatchStatType> types,
    Map<String, Player> playersById,
  ) {
    final counts = <String, int>{};
    for (final event in events) {
      final id = event.playerId;
      if (id == null || !types.contains(event.type)) continue;
      final name = playersById[id]?.name ?? 'Giocatore';
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static String _leader(Map<String, int> counts) {
    if (counts.isEmpty) return '-';
    final max = counts.values.reduce((a, b) => a > b ? a : b);
    final leaders = counts.entries
        .where((entry) => entry.value == max)
        .map((entry) => entry.key)
        .join(', ');
    return '$leaders ($max)';
  }
}

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

enum MatchDetailTab {
  facts('Fatti'),
  timeline('Timeline'),
  team('Team'),
  individual('Individuali');

  const MatchDetailTab(this.label);
  final String label;
}

enum MatchDetailSubTab {
  generali('Generali'),
  attacco('Attacco'),
  difesa('Difesa');

  const MatchDetailSubTab(this.label);
  final String label;
}

