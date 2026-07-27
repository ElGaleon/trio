import 'package:flutter_test/flutter_test.dart';
import 'package:skrim/src/features/matches/domain/individual_stat_line.dart';
import 'package:skrim/src/features/matches/domain/match_derived_stats.dart';
import 'package:skrim/src/features/matches/domain/match_stat_event.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/players/domain/player_stats_card_data.dart';

void main() {
  test('calcola break, conversioni e connessioni dai punti live', () {
    final players = {
      'a': Player(id: 'a', name: 'Anna'),
      'b': Player(id: 'b', name: 'Bruno'),
      'c': Player(id: 'c', name: 'Carla'),
    };
    final match = ScrimmageMatch(
      id: 'm1',
      createdAt: DateTime(2026),
      teamAIds: ['a', 'b', 'c'],
      teamBIds: [],
      scoreA: 2,
      scoreB: 1,
      teamARosterIds: ['a', 'b', 'c'],
      statEvents: [
        _event('l1', MatchStatType.lineup, 1, true, lineupIds: ['a', 'b', 'c']),
        _event(
          'c1',
          MatchStatType.catchDisc,
          1,
          true,
          playerId: 'a',
          discHolderId: 'a',
        ),
        _event(
          'p1',
          MatchStatType.pass,
          1,
          true,
          playerId: 'b',
          discHolderId: 'b',
        ),
        _event(
          'p2',
          MatchStatType.pass,
          1,
          true,
          playerId: 'c',
          discHolderId: 'c',
        ),
        _event('g1', MatchStatType.goal, 2, false, lineupIds: ['a', 'b', 'c']),
        _event(
          'l2',
          MatchStatType.lineup,
          2,
          false,
          lineupIds: ['a', 'b', 'c'],
        ),
        _event(
          'd1',
          MatchStatType.block,
          2,
          true,
          playerId: 'b',
          discHolderId: 'b',
        ),
        _event(
          'p3',
          MatchStatType.pass,
          2,
          true,
          playerId: 'c',
          discHolderId: 'c',
        ),
        _event('g2', MatchStatType.goal, 3, false, lineupIds: ['a', 'b', 'c']),
        _event('l3', MatchStatType.lineup, 3, true, lineupIds: ['a', 'b', 'c']),
        _event('e1', MatchStatType.throwError, 3, false, playerId: 'a'),
        _event(
          'og1',
          MatchStatType.opponentGoal,
          4,
          true,
          lineupIds: ['a', 'b', 'c'],
        ),
      ],
    );

    final stats = MatchDerivedStats.from(match, players);

    expect(stats.breaks, 1);
    expect(stats.breaksConceded, 1);
    expect(stats.generatedTurnovers, 1);
    expect(stats.dLineTurnoverRatio, 1);
    expect(stats.dLineConversionRatio, 1);
    expect(stats.oLineEffectiveness, 0.5);
    expect(stats.cleanOffenseRatio, 0.5);
    expect(stats.mostAssist, 'Bruno (2)');
    expect(stats.mostSecondaryAssist, 'Anna (1)');
    expect(stats.bestAssistGoalPair, 'Bruno -> Carla (2)');
    expect(stats.bestConnection, contains('Bruno -> Carla'));

    final rows = IndividualStatLine.from(match, players);
    final bruno = rows.singleWhere((row) => row.player.id == 'b');
    final carla = rows.singleWhere((row) => row.player.id == 'c');

    expect(bruno.assists, 2);
    expect(bruno.assistsPerPoint, closeTo(2 / 3, 0.001));
    expect(carla.goals, 2);
    expect(carla.goalsPerPoint, closeTo(2 / 3, 0.001));
    expect(carla.touchesPerPoint, closeTo(2 / 3, 0.001));

    final aggregate = PlayerStatsCardData.from(carla.player, [match]);
    expect(aggregate.pointsPlayed, 3);
    expect(aggregate.goals, 2);
    expect(aggregate.assists, 0);
    expect(aggregate.goalsPerPoint, closeTo(2 / 3, 0.001));
    expect(playerParticipatedInMatch('c', match), isTrue);
  });
}

MatchStatEvent _event(
  String id,
  MatchStatType type,
  int pointNumber,
  bool oursOnOffense, {
  String? playerId,
  String? discHolderId,
  List<String> lineupIds = const [],
}) {
  return MatchStatEvent(
    id: id,
    type: type,
    createdAt: DateTime(2026),
    pointNumber: pointNumber,
    scoreA: 0,
    scoreB: 0,
    oursOnOffense: oursOnOffense,
    playerId: playerId,
    discHolderId: discHolderId,
    lineupIds: lineupIds,
  );
}
