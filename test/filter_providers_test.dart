import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trio/models/player.dart';
import 'package:trio/models/scrimmage_match.dart';
import 'package:trio/providers/elo_providers.dart';

void main() {
  test('filters players by search, role and line with Riverpod', () {
    final players = [
      Player(
        id: '1',
        name: 'Alice',
        role: PlayerRole.handler,
        linePreference: PlayerLinePreference.offense,
      ),
      Player(
        id: '2',
        name: 'Bob',
        role: PlayerRole.cutter,
        linePreference: PlayerLinePreference.defense,
      ),
    ];
    final container = ProviderContainer(
      overrides: [rankedPlayersProvider.overrideWith((ref) => players)],
    );
    addTearDown(container.dispose);

    container.read(playersSearchQueryProvider.notifier).state = 'ali';
    container.read(playersRoleFilterProvider.notifier).state =
        PlayerRole.handler;
    container.read(playersLineFilterProvider.notifier).state =
        PlayerLinePreference.offense;

    final filtered = container.read(filteredPlayersProvider);

    expect(filtered, hasLength(1));
    expect(filtered.single.name, 'Alice');
  });

  test('filters matches by start and end date with Riverpod', () {
    final matches = [
      ScrimmageMatch(
        id: 'old',
        createdAt: DateTime(2026, 5, 1),
        teamAIds: const [],
        teamBIds: const [],
        scoreA: 1,
        scoreB: 0,
      ),
      ScrimmageMatch(
        id: 'inside',
        createdAt: DateTime(2026, 5, 20),
        teamAIds: const [],
        teamBIds: const [],
        scoreA: 1,
        scoreB: 0,
      ),
    ];
    final container = ProviderContainer(
      overrides: [matchesProvider.overrideWith((ref) => matches)],
    );
    addTearDown(container.dispose);

    container.read(matchesStartDateFilterProvider.notifier).state = DateTime(
      2026,
      5,
      10,
    );
    container.read(matchesEndDateFilterProvider.notifier).state = DateTime(
      2026,
      5,
      25,
    );

    final filtered = container.read(filteredMatchesProvider);

    expect(filtered, hasLength(1));
    expect(filtered.single.id, 'inside');
  });

  test('builds recent match teams only from matches played today', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 18);
    final yesterday = today.subtract(const Duration(days: 1));
    final players = [
      Player(id: '1', name: 'Tizio'),
      Player(id: '2', name: 'Caio'),
      Player(id: '3', name: 'Sempronio'),
      Player(id: '4', name: 'Mario'),
      Player(id: '5', name: 'Luigi'),
      Player(id: '6', name: 'Peach'),
    ];
    final matches = [
      ScrimmageMatch(
        id: 'today-latest',
        createdAt: today.add(const Duration(hours: 1)),
        teamAIds: const ['1', '2', '3'],
        teamBIds: const ['4', '5', '6'],
        teamAName: 'SQUADRA',
        teamBName: 'Rivali',
        scoreA: 11,
        scoreB: 9,
      ),
      ScrimmageMatch(
        id: 'today-duplicate',
        createdAt: today,
        teamAIds: const ['3', '2', '1'],
        teamBIds: const ['4', '5', '6'],
        teamAName: 'Nome vecchio',
        teamBName: 'Rivali vecchi',
        scoreA: 7,
        scoreB: 5,
      ),
      ScrimmageMatch(
        id: 'yesterday',
        createdAt: yesterday,
        teamAIds: const ['1', '4', '6'],
        teamBIds: const ['2', '3', '5'],
        teamAName: 'Ieri',
        teamBName: 'Ancora ieri',
        scoreA: 10,
        scoreB: 10,
      ),
    ];
    final container = ProviderContainer(
      overrides: [
        rankedPlayersProvider.overrideWith((ref) => players),
        matchesProvider.overrideWith((ref) => matches),
      ],
    );
    addTearDown(container.dispose);

    final recentTeams = container.read(recentMatchTeamsProvider);

    expect(recentTeams, hasLength(2));
    expect(recentTeams.first.name, 'SQUADRA');
    expect(recentTeams.first.playerNames, ['Tizio', 'Caio', 'Sempronio']);
    expect(recentTeams.map((team) => team.name), isNot(contains('Ieri')));
  });
}
