import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:trio/app_constants.dart';
import 'package:trio/model/app_settings.dart';
import 'package:trio/model/player.dart';
import 'package:trio/model/scrimmage_match.dart';
import 'package:trio/repositories/elo_repository.dart';
import 'package:trio/providers/elo_providers.dart';
import 'package:trio/service/live_stats_service.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
  });

  Future<RecalculatedData> getRecalculated(AppSettings settings) async {
    final playersSnap = await firestore.collection('players').get();
    final rawPlayers = playersSnap.docs.map((doc) => Player.fromMap(doc.data())).toList();

    final matchesSnap = await firestore.collection('matches').get();
    final rawMatches = matchesSnap.docs.map((doc) => ScrimmageMatch.fromMap(doc.data())).toList();

    return recalculateRatingsInMemory(
      rawPlayers: rawPlayers,
      rawMatches: rawMatches,
      settings: settings,
    );
  }

  test('updates ELO after a 3vs3 scrimmage', () async {
    final settings = AppSettings();
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
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

    recalculated = await getRecalculated(settings);

    final winners = recalculated.players.where((player) => player.wins == 1);
    final losers = recalculated.players.where((player) => player.losses == 1);
    final savedMatch = recalculated.matches.firstWhere((m) => m.id == 'match-1');

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
    final settings = AppSettings();
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
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

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
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

    recalculated = await getRecalculated(settings);

    expect(teamB.every((id) => recalculated.players.firstWhere((p) => p.id == id).wins == 1), isTrue);
    expect(teamA.every((id) => recalculated.players.firstWhere((p) => p.id == id).losses == 1), isTrue);
  });

  test('builds rating history for a player', () async {
    final settings = AppSettings();
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
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

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
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

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
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
    final settings = AppSettings(initialRating: 1200, eloKFactor: 64);
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
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

    recalculated = await getRecalculated(settings);

    final winner = recalculated.players.firstWhere((player) => player.wins == 1);

    expect(winner.rating, 1232);
  });

  test('updates ELO for variable team sizes', () async {
    final settings = AppSettings();
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    for (final name in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
      await repository.addPlayerWithLine(
        name,
        PlayerLinePreference.offense,
        PlayerRole.cutter,
      );
    }

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
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

    recalculated = await getRecalculated(settings);

    final winners = recalculated.players.where((player) => player.wins == 1);
    final savedMatch = recalculated.matches.firstWhere((m) => m.id == 'match-4v4');

    expect(winners, hasLength(4));
    expect(savedMatch.teamSize, 4);
    expect(savedMatch.initialRatings, hasLength(8));
  });

  test('updates ELO when a match ends in a draw', () async {
    final settings = AppSettings();
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
      await repository.addPlayer(name);
    }

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
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

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
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

    recalculated = await getRecalculated(settings);

    final savedMatch = recalculated.matches.firstWhere((m) => m.id == 'draw-match');

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
      recalculated.players.every((player) => player.matchesPlayed == 2),
      isTrue,
    );
    expect(teamA.every((id) => recalculated.players.firstWhere((p) => p.id == id).wins == 1), isTrue);
    expect(teamB.every((id) => recalculated.players.firstWhere((p) => p.id == id).losses == 1), isTrue);
  });

  test('allows more present players than the on-field format', () async {
    final settings = AppSettings();
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    for (final name in ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']) {
      await repository.addPlayerWithLine(
        name,
        PlayerLinePreference.offense,
        PlayerRole.cutter,
      );
    }

    recalculated = await getRecalculated(settings);
    repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
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

    recalculated = await getRecalculated(settings);

    final savedMatch = recalculated.matches.firstWhere((m) => m.id == 'match-3v3-with-subs');
    final winners = recalculated.players.where((player) => player.wins == 1);

    expect(savedMatch.teamSize, 3);
    expect(savedMatch.offenseVsDefense, isTrue);
    expect(savedMatch.initialRatings, hasLength(8));
    expect(winners, hasLength(4));
  });

  test('stores player role and line preference', () async {
    final settings = AppSettings();
    var recalculated = RecalculatedData([], []);
    var repository = EloRepository(
      matches: recalculated.matches,
      settings: settings,
      firestore: firestore,
    );

    await repository.addPlayerWithLine(
      'Handler A',
      PlayerLinePreference.offense,
      PlayerRole.handler,
    );

    recalculated = await getRecalculated(settings);

    final player = recalculated.players.single;

    expect(player.role, PlayerRole.handler);
    expect(player.linePreference, PlayerLinePreference.offense);
  });

  test(
    'stores stat weight on each event without rewriting old stats',
    () async {
      final settings1 = AppSettings(statWeights: {MatchStatType.pass: 1.5});
      var recalculated = RecalculatedData([], []);
      var repository1 = EloRepository(
        matches: recalculated.matches,
        settings: settings1,
        firestore: firestore,
      );

      for (final name in ['A', 'B', 'C', 'D', 'E', 'F']) {
        await repository1.addPlayer(name);
      }

      recalculated = await getRecalculated(settings1);
      repository1 = EloRepository(
        matches: recalculated.matches,
        settings: settings1,
        firestore: firestore,
      );

      final players = recalculated.players..sort((a, b) => b.rating.compareTo(a.rating));
      final match = ScrimmageMatch(
        id: 'stats-history',
        createdAt: DateTime(2026, 6, 5),
        teamAIds: players.take(3).map((player) => player.id).toList(),
        teamBIds: players.skip(3).take(3).map((player) => player.id).toList(),
        scoreA: 0,
        scoreB: 0,
      );
      await repository1.upsertMatch(match);

      recalculated = await getRecalculated(settings1);
      repository1 = EloRepository(
        matches: recalculated.matches,
        settings: settings1,
        firestore: firestore,
      );

      final playersById = {for (final player in recalculated.players) player.id: player};
      await LiveStatsService.instance.record(
        recalculated.matches.firstWhere((m) => m.id == 'stats-history'),
        type: MatchStatType.pass,
        player: players.first,
        playersById: playersById,
        repository: repository1,
      );

      final settings2 = AppSettings(statWeights: {MatchStatType.pass: 4.0});
      recalculated = await getRecalculated(settings2);
      final repository2 = EloRepository(
        matches: recalculated.matches,
        settings: settings2,
        firestore: firestore,
      );

      final savedMatch = recalculated.matches.firstWhere((m) => m.id == 'stats-history');
      await LiveStatsService.instance.record(
        savedMatch,
        type: MatchStatType.pass,
        player: players[1],
        playersById: playersById,
        repository: repository2,
      );

      recalculated = await getRecalculated(settings2);

      final statValues = recalculated.matches
          .firstWhere((m) => m.id == 'stats-history')
          .statEvents
          .map((event) => event.statValue)
          .toList();

      expect(statValues, [1.5, 4.0]);
    },
  );
}
