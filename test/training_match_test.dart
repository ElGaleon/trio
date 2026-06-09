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
    tempDir = await Directory.systemTemp.createTemp('trio_training_test_');
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

  test('preserves lineups between goals in training matches', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    final service = LiveStatsService.instance;

    final playerA = Player(id: 'a', name: 'A');
    final playerB = Player(id: 'b', name: 'B');
    await playersBox.put('a', playerA);
    await playersBox.put('b', playerB);

    final match = ScrimmageMatch(
      id: 'training-match-1',
      createdAt: DateTime.now(),
      teamAIds: ['a'],
      teamBIds: ['b'],
      scoreA: 0,
      scoreB: 0,
      teamARosterIds: ['a'],
      teamBRosterIds: ['b'],
      teamSize: 1,
      matchType: 'Allenamento',
      isExternalOpponent: false,
    );

    final playersById = {'a': playerA, 'b': playerB};

    // Record a Goal
    await service.record(
      match,
      type: MatchStatType.goal,
      player: playerA,
      playersById: playersById,
      repository: repository,
    );

    // Verify lineups are NOT cleared
    expect(match.teamAIds, ['a']);
    expect(match.teamBIds, ['b']);
  });

  test('clears lineups between goals in non-training matches if roster is larger than teamSize', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    final service = LiveStatsService.instance;

    final playerA1 = Player(id: 'a1', name: 'A1');
    final playerA2 = Player(id: 'a2', name: 'A2');
    final playerB = Player(id: 'b', name: 'B');
    await playersBox.put('a1', playerA1);
    await playersBox.put('a2', playerA2);
    await playersBox.put('b', playerB);

    final match = ScrimmageMatch(
      id: 'official-match-1',
      createdAt: DateTime.now(),
      teamAIds: ['a1'],
      teamBIds: ['b'],
      scoreA: 0,
      scoreB: 0,
      teamARosterIds: ['a1', 'a2'], // roster size (2) > teamSize (1)
      teamBRosterIds: ['b'],
      teamSize: 1,
      matchType: 'Classic',
      isExternalOpponent: false,
    );

    final playersById = {'a1': playerA1, 'a2': playerA2, 'b': playerB};

    // Record a Goal
    await service.record(
      match,
      type: MatchStatType.goal,
      player: playerA1,
      playersById: playersById,
      repository: repository,
    );

    // Verify lineup A is cleared (since roster is > teamSize and it's not a training match)
    expect(match.teamAIds, isEmpty);
    // Lineup B is preserved because teamBRosterIds size (1) == teamSize (1)
    expect(match.teamBIds, ['b']);
  });

  test('dynamic oursOnOffense transitions on pulls by Team A and Team B', () async {
    final repository = EloRepository(playersBox, matchesBox, AppSettings());
    final service = LiveStatsService.instance;

    final playerA = Player(id: 'a', name: 'A');
    final playerB = Player(id: 'b', name: 'B');
    await playersBox.put('a', playerA);
    await playersBox.put('b', playerB);

    final match = ScrimmageMatch(
      id: 'scrimmage-match-pull',
      createdAt: DateTime.now(),
      teamAIds: ['a'],
      teamBIds: ['b'],
      scoreA: 0,
      scoreB: 0,
      teamARosterIds: ['a'],
      teamBRosterIds: ['b'],
      teamSize: 1,
      matchType: 'Allenamento',
      isExternalOpponent: false,
    );

    // Player A (Team A) pulls -> Team A defending, Team B on offense -> oursOnOffense: false
    final resA = await service.recordPull(
      match,
      player: playerA,
      durationSeconds: 4,
      inBounds: true,
      repository: repository,
    );
    expect(resA.oursOnOffense, isFalse);
    expect(match.statEvents.last.oursOnOffense, isFalse);

    // Player B (Team B) pulls -> Team B defending, Team A on offense -> oursOnOffense: true
    final resB = await service.recordPull(
      match,
      player: playerB,
      durationSeconds: 5,
      inBounds: true,
      repository: repository,
    );
    expect(resB.oursOnOffense, isTrue);
    expect(match.statEvents.last.oursOnOffense, isTrue);
  });
}
