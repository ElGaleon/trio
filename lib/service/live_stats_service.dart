import '../model/player.dart';
import '../model/scrimmage_match.dart';
import '../repositories/elo_repository.dart';

class RecordEventResult {
  final bool scoredPoint;
  final bool finished;
  final bool halfTimeDue;
  final bool oursOnOffense;

  RecordEventResult({
    required this.scoredPoint,
    required this.finished,
    required this.halfTimeDue,
    required this.oursOnOffense,
  });
}

class LiveStatsService {
  LiveStatsService._();
  static final instance = LiveStatsService._();

  Duration remainingMatch(ScrimmageMatch match, DateTime now) {
    final end = match.createdAt.add(Duration(minutes: match.durationMinutes));
    final remaining = end.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration? activeCountdown(
    ScrimmageMatch match,
    MatchStatType type,
    int seconds,
    DateTime now,
  ) {
    if (seconds <= 0) return null;
    final events = match.statEvents.where((event) => event.type == type);
    if (events.isEmpty) return null;
    final startedAt = events.last.createdAt;
    final endType = type == MatchStatType.timeout
        ? MatchStatType.timeoutEnd
        : MatchStatType.halfTimeEnd;
    final endedAfterStart = match.statEvents.any(
      (event) => event.type == endType && event.createdAt.isAfter(startedAt),
    );
    if (endedAfterStart) return null;
    final end = startedAt.add(Duration(seconds: seconds));
    final remaining = end.difference(now);
    return remaining.isNegative ? null : remaining;
  }

  bool isHalfTimeDue(ScrimmageMatch match, DateTime now) {
    if (!match.hasHalfTime || hasHalfTimeEvent(match)) return false;
    final halfScore = (match.pointsLimit / 2).floor() + 1;
    final scoreReached = match.scoreA >= halfScore || match.scoreB >= halfScore;
    final timeReached =
        now.difference(match.createdAt).inMinutes >= match.durationMinutes / 2;
    return scoreReached || timeReached;
  }

  bool hasHalfTimeEvent(ScrimmageMatch match) {
    return match.statEvents.any(
      (event) => event.type == MatchStatType.halfTime,
    );
  }

  int pointsPlayed(ScrimmageMatch match, String playerId) {
    return match.statEvents.where((event) {
      final pointEnded =
          event.type == MatchStatType.goal ||
          event.type == MatchStatType.opponentGoal;
      return pointEnded && event.lineupIds.contains(playerId);
    }).length;
  }

  Future<RecordEventResult> record(
    ScrimmageMatch match, {
    required MatchStatType type,
    Player? player,
    required Map<String, Player> playersById,
    required EloRepository repository,
  }) async {
    final lastEvent = match.statEvents.isEmpty ? null : match.statEvents.last;
    var scoreA = match.scoreA;
    var scoreB = match.scoreB;
    var point = lastEvent?.pointNumber ?? 1;
    var oursOnOffense = lastEvent?.oursOnOffense ?? true;
    String? discHolderId = lastEvent?.discHolderId;
    final previousHolder = discHolderId == null
        ? null
        : playersById[discHolderId];

    final scoredPoint =
        type == MatchStatType.goal || type == MatchStatType.opponentGoal;
    if (type == MatchStatType.goal) {
      scoreA += 1;
      point += 1;
      oursOnOffense = false;
      discHolderId = null;
    } else if (type == MatchStatType.opponentGoal) {
      scoreB += 1;
      point += 1;
      oursOnOffense = true;
      discHolderId = null;
    } else if (type == MatchStatType.timeout ||
        type == MatchStatType.injury ||
        type == MatchStatType.halfTime ||
        type == MatchStatType.timeoutEnd ||
        type == MatchStatType.halfTimeEnd ||
        type == MatchStatType.matchEnd ||
        type == MatchStatType.pull) {
      // No possession change.
    } else if (type == MatchStatType.pass || type == MatchStatType.huck) {
      oursOnOffense = true;
      discHolderId = player?.id;
    } else if (type == MatchStatType.catchDisc) {
      oursOnOffense = true;
      discHolderId = player?.id;
    } else if (type == MatchStatType.defense || type == MatchStatType.block) {
      oursOnOffense = true;
      discHolderId = player?.id;
    } else if (type == MatchStatType.opponentError) {
      oursOnOffense = true;
      discHolderId = null;
    } else if (type.isError) {
      oursOnOffense = false;
      discHolderId = null;
    }

    final event = MatchStatEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      createdAt: DateTime.now(),
      pointNumber: point,
      scoreA: scoreA,
      scoreB: scoreB,
      oursOnOffense: oursOnOffense,
      playerId: player?.id,
      discHolderId: discHolderId,
      lineupIds: match.teamAIds,
      statValue: player == null
          ? null
          : repository.settings.statWeightFor(type),
      description: _descriptionFor(
        type: type,
        player: player,
        previousHolder: previousHolder,
      ),
    );

    match
      ..scoreA = scoreA
      ..scoreB = scoreB
      ..statEvents = [...match.statEvents, event];
    await repository.upsertMatch(match);

    final finished = scoreA >= match.pointsLimit || scoreB >= match.pointsLimit;
    final halfTime = isHalfTimeDue(match, DateTime.now());

    return RecordEventResult(
      scoredPoint: scoredPoint,
      finished: finished,
      halfTimeDue: halfTime,
      oursOnOffense: oursOnOffense,
    );
  }

  Future<RecordEventResult> recordPull(
    ScrimmageMatch match, {
    required Player player,
    required int durationSeconds,
    required bool inBounds,
    required EloRepository repository,
  }) async {
    final lastEvent = match.statEvents.isEmpty ? null : match.statEvents.last;
    final event = MatchStatEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: MatchStatType.pull,
      createdAt: DateTime.now(),
      pointNumber: lastEvent?.pointNumber ?? 1,
      scoreA: match.scoreA,
      scoreB: match.scoreB,
      oursOnOffense: false,
      playerId: player.id,
      discHolderId: lastEvent?.discHolderId,
      lineupIds: match.teamAIds,
      pullDurationSeconds: durationSeconds,
      pullInBounds: inBounds,
      statValue: repository.settings.statWeightFor(MatchStatType.pull),
      description:
          '${player.name} · Pull ${durationSeconds}s · ${inBounds ? 'dentro' : 'fuori'}',
    );

    match.statEvents = [...match.statEvents, event];
    await repository.upsertMatch(match);

    return RecordEventResult(
      scoredPoint: false,
      finished: false,
      halfTimeDue: isHalfTimeDue(match, DateTime.now()),
      oursOnOffense: false,
    );
  }

  Future<void> endPause(
    ScrimmageMatch match,
    String title,
    MatchStatType endType,
    bool nextOnOffense,
    EloRepository repository,
  ) async {
    final last = match.statEvents.lastOrNull;
    match.statEvents = [
      ...match.statEvents,
      MatchStatEvent(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: endType,
        createdAt: DateTime.now(),
        pointNumber: last?.pointNumber ?? 1,
        scoreA: match.scoreA,
        scoreB: match.scoreB,
        oursOnOffense: last?.oursOnOffense ?? nextOnOffense,
        discHolderId: last?.discHolderId,
        lineupIds: match.teamAIds,
        description: 'Fine ${title.toLowerCase()}',
      ),
    ];
    await repository.upsertMatch(match);
  }

  Future<void> finishMatch(
    ScrimmageMatch match,
    EloRepository repository,
  ) async {
    if (!match.statEvents.any(
      (event) => event.type == MatchStatType.matchEnd,
    )) {
      match.statEvents = [
        ...match.statEvents,
        MatchStatEvent(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: MatchStatType.matchEnd,
          createdAt: DateTime.now(),
          pointNumber: match.statEvents.lastOrNull?.pointNumber ?? 1,
          scoreA: match.scoreA,
          scoreB: match.scoreB,
          oursOnOffense: match.statEvents.lastOrNull?.oursOnOffense ?? true,
          lineupIds: match.teamAIds,
          description: 'Partita conclusa',
        ),
      ];
      await repository.upsertMatch(match);
    }
  }

  Future<void> undo(ScrimmageMatch match, EloRepository repository) async {
    if (match.statEvents.isEmpty) return;
    final events = [...match.statEvents]..removeLast();
    final last = events.isEmpty ? null : events.last;
    match
      ..scoreA = last?.scoreA ?? 0
      ..scoreB = last?.scoreB ?? 0
      ..statEvents = events;
    await repository.upsertMatch(match);
  }

  Future<void> updateLineup(
    ScrimmageMatch match,
    List<String> playerIds,
    bool nextOnOffense,
    EloRepository repository,
  ) async {
    if (match.statEvents.isEmpty) return;
    final last = match.statEvents.last;
    match
      ..teamAIds = playerIds
      ..statEvents = [
        ...match.statEvents,
        MatchStatEvent(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: MatchStatType.lineup,
          createdAt: DateTime.now(),
          pointNumber: last.pointNumber,
          scoreA: match.scoreA,
          scoreB: match.scoreB,
          oursOnOffense: nextOnOffense,
          lineupIds: playerIds,
          description:
              'Linea ${nextOnOffense ? 'attacco' : 'difesa'} selezionata',
        ),
      ];
    await repository.upsertMatch(match);
  }

  Future<void> replaceInjuredPlayer(
    ScrimmageMatch match, {
    required Player injured,
    required Player replacement,
    required bool oursOnOffense,
    required EloRepository repository,
  }) async {
    if (!match.teamAIds.contains(injured.id)) return;
    final last = match.statEvents.lastOrNull;
    final newLineup = match.teamAIds
        .map((id) => id == injured.id ? replacement.id : id)
        .toList();
    final nextDiscHolderId = last?.discHolderId == injured.id
        ? replacement.id
        : last?.discHolderId;

    match
      ..teamAIds = newLineup
      ..statEvents = [
        ...match.statEvents,
        MatchStatEvent(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: MatchStatType.injury,
          createdAt: DateTime.now(),
          pointNumber: last?.pointNumber ?? 1,
          scoreA: match.scoreA,
          scoreB: match.scoreB,
          oursOnOffense: oursOnOffense,
          playerId: injured.id,
          discHolderId: nextDiscHolderId,
          lineupIds: newLineup,
          description: '${injured.name} infortunio · entra ${replacement.name}',
        ),
      ];
    await repository.upsertMatch(match);
  }

  String _descriptionFor({
    required MatchStatType type,
    Player? player,
    Player? previousHolder,
  }) {
    if (type == MatchStatType.pass || type == MatchStatType.huck) {
      final receiver = player?.name ?? 'ricevitore';
      final thrower = previousHolder?.name ?? 'Disco';
      return '$thrower · ${type.label} verso $receiver';
    }
    if (type == MatchStatType.catchError && player != null) {
      return '${player.name} · Receive error';
    }
    if (type == MatchStatType.opponentError) {
      return 'Throwaway avversario';
    }
    if (type == MatchStatType.goal) {
      return 'Meta nostra';
    }
    if (type == MatchStatType.opponentGoal) {
      return 'Meta avversaria';
    }
    if (type == MatchStatType.halfTime) {
      return 'Half time avviato';
    }
    if (type == MatchStatType.timeoutEnd) {
      return 'Timeout terminato';
    }
    if (type == MatchStatType.halfTimeEnd) {
      return 'Half time terminato';
    }
    if (type == MatchStatType.matchEnd) {
      return 'Partita conclusa';
    }
    if (type == MatchStatType.pull) {
      return player == null ? 'Pull' : '${player.name} · Pull';
    }
    return player == null ? type.label : '${player.name} · ${type.label}';
  }
}
