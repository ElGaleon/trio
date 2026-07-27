import 'package:skrim/src/features/players/domain/player.dart';

import 'match_stat_event.dart';
import 'match_stat_type.dart';
import 'scrimmage_match.dart';

class MatchDerivedStats {
  const MatchDerivedStats({
    required this.goals,
    required this.opponentGoals,
    required this.turnovers,
    required this.breaks,
    required this.breaksConceded,
    required this.generatedTurnovers,
    required this.passAccuracy,
    required this.oLineEffectiveness,
    required this.cleanOffenseRatio,
    required this.dLineTurnoverRatio,
    required this.dLineConversionRatio,
    required this.topScorer,
    required this.mostAssist,
    required this.mostSecondaryAssist,
    required this.mostTouches,
    required this.bestDefender,
    required this.mostPlayed,
    required this.bestConnection,
    required this.bestAssistGoalPair,
    required this.pointsPlayed,
  });

  final int goals;
  final int opponentGoals;
  final int turnovers;
  final int breaks;
  final int breaksConceded;
  final int generatedTurnovers;
  final double passAccuracy;
  final double oLineEffectiveness;
  final double cleanOffenseRatio;
  final double dLineTurnoverRatio;
  final double dLineConversionRatio;
  final String topScorer;
  final String mostAssist;
  final String mostSecondaryAssist;
  final String mostTouches;
  final String bestDefender;
  final String mostPlayed;
  final String bestConnection;
  final String bestAssistGoalPair;
  final List<({String name, int value})> pointsPlayed;

  static MatchDerivedStats from(
    ScrimmageMatch match,
    Map<String, Player> playersById,
  ) {
    final events = match.statEvents;
    final pointStarts = <int, bool>{};
    for (final event in events) {
      if (_endsPoint(event)) continue;
      pointStarts.putIfAbsent(event.pointNumber, () => event.oursOnOffense);
    }

    final ourGoalEvents = events.where((e) => e.type == MatchStatType.goal);
    final opponentGoalEvents = events.where(
      (e) => e.type == MatchStatType.opponentGoal,
    );
    final oLineStarts = pointStarts.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toSet();
    final dLineStarts = pointStarts.entries
        .where((entry) => !entry.value)
        .map((entry) => entry.key)
        .toSet();
    final oLineGoals = ourGoalEvents
        .where((event) => oLineStarts.contains(_scoredPoint(event)))
        .length;
    final dLineGoals = ourGoalEvents
        .where((event) => dLineStarts.contains(_scoredPoint(event)))
        .length;
    final cleanOffenseGoals = ourGoalEvents.where((goal) {
      final point = _scoredPoint(goal);
      if (!oLineStarts.contains(point)) return false;
      return !events.any(
        (event) => event.pointNumber == point && event.type.isError,
      );
    }).length;
    final generatedTurnovers = dLineStarts.where((point) {
      return events.any(
        (event) =>
            event.pointNumber == point &&
            (event.type == MatchStatType.opponentError ||
                event.type == MatchStatType.block ||
                event.type == MatchStatType.defense),
      );
    }).length;
    final breaksConceded = opponentGoalEvents
        .where((event) => oLineStarts.contains(_scoredPoint(event)))
        .length;

    final passChains = _passChains(events);
    final playerGoals = _goalScorers(events, playersById);
    final playerAssists = _assists(passChains, events, playersById);
    final playerSecondaryAssists = _secondaryAssists(
      passChains,
      events,
      playersById,
    );
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
    final connectionCounts = <String, int>{};
    for (final pass in passChains) {
      final thrower = _name(playersById, pass.throwerId);
      final receiver = _name(playersById, pass.receiverId);
      if (thrower == null || receiver == null) continue;
      connectionCounts.update(
        '$thrower -> $receiver',
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final playedCounts = <String, int>{};
    for (final event in events.where(_endsPoint)) {
      for (final id in event.lineupIds) {
        final name = _name(playersById, id);
        if (name == null) continue;
        playedCounts.update(name, (value) => value + 1, ifAbsent: () => 1);
      }
    }
    final pointsPlayed =
        playedCounts.entries
            .map((entry) => (name: entry.key, value: entry.value))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return MatchDerivedStats(
      goals: ourGoalEvents.length,
      opponentGoals: opponentGoalEvents.length,
      turnovers: events.where((event) => event.type.isError).length,
      breaks: dLineGoals,
      breaksConceded: breaksConceded,
      generatedTurnovers: generatedTurnovers,
      passAccuracy: _ratio(match.completedPasses, match.attemptedPasses),
      oLineEffectiveness: _ratio(oLineGoals, oLineStarts.length),
      cleanOffenseRatio: _ratio(cleanOffenseGoals, oLineStarts.length),
      dLineTurnoverRatio: _ratio(generatedTurnovers, dLineStarts.length),
      dLineConversionRatio: _ratio(dLineGoals, generatedTurnovers),
      topScorer: _leader(playerGoals),
      mostAssist: _leader(playerAssists),
      mostSecondaryAssist: _leader(playerSecondaryAssists),
      mostTouches: _leader(playerTouches),
      bestDefender: _leader(playerDefenses),
      mostPlayed: pointsPlayed.isEmpty
          ? '-'
          : '${pointsPlayed.first.name} (${pointsPlayed.first.value})',
      bestConnection: _leader(connectionCounts),
      bestAssistGoalPair: _bestAssistGoalPair(passChains, events, playersById),
      pointsPlayed: pointsPlayed,
    );
  }

  static bool _endsPoint(MatchStatEvent event) {
    return event.type == MatchStatType.goal ||
        event.type == MatchStatType.opponentGoal;
  }

  static int _scoredPoint(MatchStatEvent event) {
    return event.pointNumber > 1 ? event.pointNumber - 1 : event.pointNumber;
  }

  static List<_PassLink> _passChains(List<MatchStatEvent> events) {
    final links = <_PassLink>[];
    String? holderId;
    for (final event in events) {
      if (_endsPoint(event)) {
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

  static Map<String, int> _goalScorers(
    List<MatchStatEvent> events,
    Map<String, Player> playersById,
  ) {
    final counts = <String, int>{};
    final links = _passChains(events);
    for (final goal in events.where((e) => e.type == MatchStatType.goal)) {
      final scorerId =
          goal.playerId ??
          links
              .where((link) => link.pointNumber == _scoredPoint(goal))
              .lastOrNull
              ?.receiverId;
      final name = _name(playersById, scorerId);
      if (name == null) continue;
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static Map<String, int> _assists(
    List<_PassLink> links,
    List<MatchStatEvent> events,
    Map<String, Player> playersById,
  ) {
    final counts = <String, int>{};
    for (final goal in events.where((e) => e.type == MatchStatType.goal)) {
      final assistId = links
          .where((link) => link.pointNumber == _scoredPoint(goal))
          .lastOrNull
          ?.throwerId;
      final name = _name(playersById, assistId);
      if (name == null) continue;
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static Map<String, int> _secondaryAssists(
    List<_PassLink> links,
    List<MatchStatEvent> events,
    Map<String, Player> playersById,
  ) {
    final counts = <String, int>{};
    for (final goal in events.where((e) => e.type == MatchStatType.goal)) {
      final pointLinks = links
          .where((link) => link.pointNumber == _scoredPoint(goal))
          .toList();
      if (pointLinks.length < 2) continue;
      final name = _name(
        playersById,
        pointLinks[pointLinks.length - 2].throwerId,
      );
      if (name == null) continue;
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static String _bestAssistGoalPair(
    List<_PassLink> links,
    List<MatchStatEvent> events,
    Map<String, Player> playersById,
  ) {
    final counts = <String, int>{};
    for (final goal in events.where((e) => e.type == MatchStatType.goal)) {
      final assist = links
          .where((link) => link.pointNumber == _scoredPoint(goal))
          .lastOrNull;
      if (assist == null) continue;
      final thrower = _name(playersById, assist.throwerId);
      final scorer = _name(playersById, goal.playerId ?? assist.receiverId);
      if (thrower == null || scorer == null) continue;
      counts.update(
        '$thrower -> $scorer',
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    return _leader(counts);
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
      final name = _name(playersById, id);
      if (name == null) continue;
      counts.update(name, (value) => value + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  static String? _name(Map<String, Player> playersById, String? id) {
    if (id == null) return null;
    return playersById[id]?.name ?? 'Giocatore';
  }

  static double _ratio(int numerator, int denominator) {
    return denominator == 0 ? 0 : numerator / denominator;
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
