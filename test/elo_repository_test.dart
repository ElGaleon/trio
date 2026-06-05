import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trio/adapters/player_adapter.dart';
import 'package:trio/adapters/scrimmage_match_adapter.dart';
import 'package:trio/app_constants.dart';
import 'package:trio/model/app_settings.dart';
import 'package:trio/model/player.dart';
import 'package:trio/model/scrimmage_match.dart';
import 'package:trio/repositories/elo_repository.dart';
import 'package:trio/service/live_stats_service.dart';

void main() {
  late Directory tempDir;
  late Box<Player> playersBox;
  late Box<ScrimmageMatch> matchesBox;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('trio_elo_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(AppConstants.playerTypeId)) {
      Hive.registerAdapter(PlayerAdapter());
    }
    if (!Hive.isAdapterRegistered(AppConstants.matchTypeId)) {
      Hive.registerAdapter(ScrimmageMatchAdapter());
    }
    playersBox = await Hive.openBox<Player>('players_test');
    matchesBox = await Hive.openBox<ScrimmageMatch>('matches_test');
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('updates ELO after a 3vs3 scrimmage', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }

    final players = repository.rankedPlayers;
    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-1',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: players.take(3).map((player) => player.id).toList(),
        teamBIds: players.skip(3).take(3).map((player) => player.id).toList(),
        scoreA: 21,
        scoreB: 18,
      ),
    );

    final winners = playersBox.values.where((player) => player.wins == 1);
    final losers = playersBox.values.where((player) => player.losses == 1);
    final savedMatch = matchesBox.get('match-1')!;

    expect(winners, hasLength(3));
    expect(losers, hasLength(3));
    expect(savedMatch.initialRatings, hasLength(6));
    expect(savedMatch.finalRatings, hasLength(6));
    expect(
      winners.every((player) => player.rating > AppConstants.initialRating),
      isTrue,
    );
    expect(
      losers.every((player) => player.rating < AppConstants.initialRating),
      isTrue,
    );
  });

  test('recalculates ratings when a match is edited', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }
    final players = repository.rankedPlayers;
    final teamA = players.take(3).map((player) => player.id).toList();
    final teamB = players.skip(3).take(3).map((player) => player.id).toList();

    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-1',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: teamA,
        teamBIds: teamB,
        scoreA: 21,
        scoreB: 18,
      ),
    );
    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-1',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: teamA,
        teamBIds: teamB,
        scoreA: 17,
        scoreB: 21,
      ),
    );

    expect(teamB.every((id) => playersBox.get(id)!.wins == 1), isTrue);
    expect(teamA.every((id) => playersBox.get(id)!.losses == 1), isTrue);
  });

  test('builds rating history for a player', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }
    final players = repository.rankedPlayers;
    final trackedPlayerId = players.first.id;
    final teamA = players.take(3).map((player) => player.id).toList();
    final teamB = players.skip(3).take(3).map((player) => player.id).toList();

    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-1',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: teamA,
        teamBIds: teamB,
        scoreA: 21,
        scoreB: 18,
      ),
    );
    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-2',
        createdAt: DateTime(2026, 5, 27),
        teamAIds: teamA,
        teamBIds: teamB,
        scoreA: 16,
        scoreB: 21,
      ),
    );

    final history = repository.ratingHistoryForPlayer(trackedPlayerId);
    final playedMatches = repository.matchesForPlayer(trackedPlayerId);

    expect(history, hasLength(3));
    expect(history.first, AppConstants.initialRating);
    expect(history[1], greaterThan(history.first));
    expect(history.last, lessThan(history[1]));
    expect(playedMatches, hasLength(2));
  });

  test('uses configurable initial rating and ELO coefficient', () async {
    final repository = EloRepository(
      playersBox,
      matchesBox,
      AppSettings(initialRating: 1200, eloKFactor: 64),
    );
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }

    final players = repository.rankedPlayers;
    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-1',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: players.take(3).map((player) => player.id).toList(),
        teamBIds: players.skip(3).take(3).map((player) => player.id).toList(),
        scoreA: 21,
        scoreB: 18,
      ),
    );

    final winner = playersBox.values.firstWhere((player) => player.wins == 1);

    expect(winner.rating, 1232);
  });

  test('updates ELO for variable team sizes', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
      await repository.addPlayerWithLine(
        name,
        PlayerLinePreference.offense,
        PlayerRole.cutter,
      );
    }

    final players = repository.rankedPlayers;
    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-4v4',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: players.take(4).map((player) => player.id).toList(),
        teamBIds: players.skip(4).take(4).map((player) => player.id).toList(),
        scoreA: 15,
        scoreB: 12,
        teamSize: 4,
      ),
    );

    final winners = playersBox.values.where((player) => player.wins == 1);
    final savedMatch = matchesBox.get('match-4v4')!;

    expect(winners, hasLength(4));
    expect(savedMatch.teamSize, 4);
    expect(savedMatch.initialRatings, hasLength(8));
  });

  test('updates ELO when a match ends in a draw', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }
    final players = repository.rankedPlayers;
    final teamA = players.take(3).map((player) => player.id).toList();
    final teamB = players.skip(3).take(3).map((player) => player.id).toList();

    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'decisive-match',
        createdAt: DateTime(2026, 5, 25),
        teamAIds: teamA,
        teamBIds: teamB,
        scoreA: 13,
        scoreB: 9,
      ),
    );

    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'draw-match',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: teamA,
        teamBIds: teamB,
        scoreA: 10,
        scoreB: 10,
      ),
    );

    final savedMatch = matchesBox.get('draw-match')!;

    expect(savedMatch.isDraw, isTrue);
    expect(
      teamA.every(
        (id) => savedMatch.finalRatings[id]! < savedMatch.initialRatings[id]!,
      ),
      isTrue,
    );
    expect(
      teamB.every(
        (id) => savedMatch.finalRatings[id]! > savedMatch.initialRatings[id]!,
      ),
      isTrue,
    );
    expect(
      playersBox.values.every((player) => player.matchesPlayed == 2),
      isTrue,
    );
    expect(teamA.every((id) => playersBox.get(id)!.wins == 1), isTrue);
    expect(teamB.every((id) => playersBox.get(id)!.losses == 1), isTrue);
  });

  test('allows more present players than the on-field format', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    for (final name in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
      await repository.addPlayerWithLine(
        name,
        PlayerLinePreference.offense,
        PlayerRole.cutter,
      );
    }

    final players = repository.rankedPlayers;
    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'match-3v3-with-subs',
        createdAt: DateTime(2026, 5, 26),
        teamAIds: players.take(4).map((player) => player.id).toList(),
        teamBIds: players.skip(4).take(4).map((player) => player.id).toList(),
        scoreA: 13,
        scoreB: 9,
        teamSize: 3,
        offenseVsDefense: true,
      ),
    );

    final savedMatch = matchesBox.get('match-3v3-with-subs')!;
    final winners = playersBox.values.where((player) => player.wins == 1);

    expect(savedMatch.teamSize, 3);
    expect(savedMatch.offenseVsDefense, isTrue);
    expect(savedMatch.initialRatings, hasLength(8));
    expect(winners, hasLength(4));
  });

  test('stores player role and line preference', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());

    await repository.addPlayerWithLine(
      'Handler A',
      PlayerLinePreference.offense,
      PlayerRole.handler,
    );

    final player = playersBox.values.single;

    expect(player.role, PlayerRole.handler);
    expect(player.linePreference, PlayerLinePreference.offense);
  });

  test(
    'stores stat weight on each event without rewriting old stats',
    () async {
      final firstRepository = EloRepository(
        playersBox,
        matchesBox,
        AppSettings(statWeights: {MatchStatType.pass: 1.5}),
      );
      for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
        await firstRepository.addPlayer(name);
      }
      final players = firstRepository.rankedPlayers;
      final match = ScrimmageMatch(
        id: 'stats-history',
        createdAt: DateTime(2026, 6, 5),
        teamAIds: players.take(3).map((player) => player.id).toList(),
        teamBIds: players.skip(3).take(3).map((player) => player.id).toList(),
        scoreA: 0,
        scoreB: 0,
      );
      await firstRepository.upsertMatch(match);

      final playersById = {for (final player in players) player.id: player};
      await LiveStatsService.instance.record(
        match,
        type: MatchStatType.pass,
        player: players.first,
        playersById: playersById,
        repository: firstRepository,
      );

      final secondRepository = EloRepository(
        playersBox,
        matchesBox,
        AppSettings(statWeights: {MatchStatType.pass: 4}),
      );
      final savedMatch = matchesBox.get('stats-history')!;
      await LiveStatsService.instance.record(
        savedMatch,
        type: MatchStatType.pass,
        player: players[1],
        playersById: playersById,
        repository: secondRepository,
      );

      final statValues = matchesBox
          .get('stats-history')!
          .statEvents
          .map((event) => event.statValue)
          .toList();

      expect(statValues, [1.5, 4]);
    },
  );
}
