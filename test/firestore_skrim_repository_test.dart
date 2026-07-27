import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skrim/src/features/events/domain/team_event.dart';
import 'package:skrim/src/features/firebase/data/firestore_skrim_repository.dart';
import 'package:skrim/src/features/live_stats/application/live_stats_service.dart';
import 'package:skrim/src/features/matches/domain/match_stat_event.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/domain/player_role.dart';
import 'package:skrim/src/features/settings/domain/app_settings.dart';

void main() {
  test(
    'streams live match updates from the shared Firestore collections',
    () async {
      final firestore = FakeFirebaseFirestore();
      final repository = FirestoreSkrimRepository(
        firestore: firestore,
        organizationId: 'org-1',
      );

      await repository.addPlayerWithLine(
        'Alice',
        firstName: 'Alice',
        lastName: 'Rossi',
        email: 'alice@example.com',
        linePreference: null,
        role: PlayerRole.handler,
      );
      await repository.addPlayerWithLine(
        'Bob',
        linePreference: null,
        role: PlayerRole.cutter,
      );

      final players = await repository.watchPlayers().first;
      expect(players, hasLength(2));
      expect(
        players.map((player) => player.name),
        containsAll(['Alice', 'Bob']),
      );
      expect(
        players.where((player) => player.name == 'Alice').single.email,
        'alice@example.com',
      );

      final match = ScrimmageMatch(
        id: 'match-1',
        createdAt: DateTime(2026, 7, 17),
        teamAIds: const ['a'],
        teamBIds: const ['b'],
        scoreA: 0,
        scoreB: 0,
      );
      await repository.upsertMatch(match);

      final updated = await repository.updateMatchTransaction('match-1', (
        current,
      ) {
        current
          ..scoreA = 1
          ..statEvents = [
            ...current.statEvents,
            MatchStatEvent(
              id: 'event-1',
              type: MatchStatType.goal,
              createdAt: DateTime(2026, 7, 17, 12),
              pointNumber: 1,
              scoreA: 1,
              scoreB: 0,
              oursOnOffense: false,
            ),
          ];
        return current;
      });

      expect(updated.scoreA, 1);
      final streamed = await repository
          .watchMatch('match-1')
          .firstWhere((match) => match?.statEvents.isNotEmpty == true);
      expect(streamed?.statEvents.single.id, 'event-1');
    },
  );

  test('collaborates on live match updates through realtime streams', () async {
    final firestore = FakeFirebaseFirestore();
    final clientA = FirestoreSkrimRepository(
      firestore: firestore,
      organizationId: 'org-1',
    );
    final clientB = FirestoreSkrimRepository(
      firestore: firestore,
      organizationId: 'org-1',
    );

    final playerId = await clientA.addPlayerWithLine(
      'Alice',
      linePreference: null,
      role: PlayerRole.handler,
    );
    await clientA.upsertMatch(
      ScrimmageMatch(
        id: 'live-1',
        createdAt: DateTime(2026, 7, 22, 20),
        teamAIds: [playerId],
        teamBIds: const [],
        scoreA: 0,
        scoreB: 0,
      ),
    );

    final player = (await clientA.watchPlayers().first).single;
    final streamedFromClientB = clientB
        .watchMatch('live-1')
        .firstWhere((match) => match?.statEvents.isNotEmpty == true);

    await LiveStatsService.instance.record(
      (await clientA.watchMatch('live-1').first)!,
      type: MatchStatType.pass,
      player: player,
      playersById: {player.id: player},
      repository: clientA,
      settings: AppSettings(),
    );

    final received = await streamedFromClientB;
    expect(received?.statEvents.single.type, MatchStatType.pass);
    expect(received?.statEvents.single.playerId, playerId);
  });

  test('creates updates and deletes calendar events', () async {
    final firestore = FakeFirebaseFirestore();
    final repository = FirestoreSkrimRepository(
      firestore: firestore,
      organizationId: 'org-1',
    );

    final eventId = await repository.addEvent(
      TeamEvent(
        id: '',
        title: 'Allenamento',
        startAt: DateTime(2026, 7, 21, 19),
        endAt: DateTime(2026, 7, 21, 21),
        location: 'Campo Nord',
        notes: 'Portare maglia bianca e scura',
        type: TeamEventType.training,
        presentPlayerIds: const ['alice', 'bob'],
      ),
    );

    var events = await repository.watchEvents().first;
    expect(events.single.id, eventId);
    expect(events.single.location, 'Campo Nord');
    expect(events.single.type, TeamEventType.training);
    expect(events.single.presentPlayerIds, ['alice', 'bob']);

    await repository.upsertMatch(
      ScrimmageMatch(
        id: 'training-match-1',
        createdAt: DateTime(2026, 7, 21, 19, 15),
        teamAIds: const ['a'],
        teamBIds: const ['b'],
        scoreA: 0,
        scoreB: 0,
        trainingEventId: eventId,
      ),
    );
    await repository.linkMatchToEvent(eventId, 'training-match-1');
    events = await repository.watchEvents().firstWhere(
      (events) => events.single.matchIds.contains('training-match-1'),
    );
    expect(events.single.matchIds, contains('training-match-1'));

    await repository.saveEvent(
      events.single.copyWith(
        recurrence: TeamEventRecurrence.weekly,
        recurrenceEndsAt: DateTime(2026, 8, 4),
      ),
    );
    events = await repository.watchEvents().firstWhere(
      (events) => events.single.recurrence == TeamEventRecurrence.weekly,
    );
    expect(events.single.recurrenceEndsAt, DateTime(2026, 8, 4));

    await repository.saveEvent(
      events.single.copyWith(location: 'Campo Sud', notes: ''),
    );
    events = await repository.watchEvents().firstWhere(
      (events) => events.single.location == 'Campo Sud',
    );
    expect(events.single.notes, isEmpty);

    await repository.deleteEvent(eventId);
    events = await repository.watchEvents().firstWhere(
      (events) => events.isEmpty,
    );
    expect(events, isEmpty);
  });

  test('isolates data by organization', () async {
    final firestore = FakeFirebaseFirestore();
    final orgA = FirestoreSkrimRepository(
      firestore: firestore,
      organizationId: 'org-a',
    );
    final orgB = FirestoreSkrimRepository(
      firestore: firestore,
      organizationId: 'org-b',
    );

    await orgA.addPlayerWithLine(
      'Alice',
      linePreference: null,
      role: PlayerRole.handler,
    );
    await orgB.addPlayerWithLine(
      'Bob',
      linePreference: null,
      role: PlayerRole.cutter,
    );

    expect((await orgA.watchPlayers().first).map((player) => player.name), [
      'Alice',
    ]);
    expect((await orgB.watchPlayers().first).map((player) => player.name), [
      'Bob',
    ]);
  });
}
