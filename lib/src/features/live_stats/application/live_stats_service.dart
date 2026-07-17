import 'package:trio/src/features/matches/data/elo_repository.dart';
import 'package:trio/src/features/matches/domain/match_stat_event.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/settings/domain/custom_stat.dart';
import 'record_event_result.dart';

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
    String? customStatId,
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

    final isPlayerTeamA =
        player == null ||
        (match.isExternalOpponent
            ? true
            : !match.teamBRosterIds.contains(player.id));
    final activeLineupA = [...match.teamAIds];
    final activeLineupB = [...match.teamBIds];

    final scoredPoint =
        type == MatchStatType.goal || type == MatchStatType.opponentGoal;

    final shouldClearA =
        match.matchType != 'Allenamento' &&
        (match.isExternalOpponent
            ? match.presentPlayerIds.length > match.teamSize
            : match.teamARosterIds.length > match.teamSize);
    final shouldClearB =
        match.matchType != 'Allenamento' &&
        (!match.isExternalOpponent &&
            match.teamBRosterIds.length > match.teamSize);

    bool isCustomError = false;
    double? customWeight;
    String? customLabel;
    if (type == MatchStatType.custom && customStatId != null) {
      final customStat = repository.settings.customStats.firstWhere(
        (s) => s.id == customStatId,
        orElse: () => CustomStat(
          id: '',
          label: '',
          abbreviation: '',
          isError: false,
          weight: 0.0,
        ),
      );
      isCustomError = customStat.isError;
      customWeight = customStat.weight;
      customLabel = customStat.label;
    }

    if (type == MatchStatType.goal) {
      scoreA += 1;
      point += 1;
      oursOnOffense = false;
      discHolderId = null;
      if (shouldClearA) match.teamAIds = [];
      if (shouldClearB) match.teamBIds = [];
    } else if (type == MatchStatType.opponentGoal) {
      scoreB += 1;
      point += 1;
      oursOnOffense = true;
      discHolderId = null;
      if (shouldClearA) match.teamAIds = [];
      if (shouldClearB) match.teamBIds = [];
    } else if (type == MatchStatType.timeout ||
        type == MatchStatType.injury ||
        type == MatchStatType.halfTime ||
        type == MatchStatType.timeoutEnd ||
        type == MatchStatType.halfTimeEnd ||
        type == MatchStatType.matchEnd ||
        type == MatchStatType.pull) {
      // No possession change.
    } else if (type == MatchStatType.pass || type == MatchStatType.huck) {
      oursOnOffense = isPlayerTeamA;
      discHolderId = player?.id;
    } else if (type == MatchStatType.catchDisc) {
      oursOnOffense = isPlayerTeamA;
      discHolderId = player?.id;
    } else if (type == MatchStatType.defense || type == MatchStatType.block) {
      oursOnOffense = isPlayerTeamA;
      discHolderId = player?.id;
    } else if (type == MatchStatType.opponentError) {
      oursOnOffense = true;
      discHolderId = null;
    } else if (type.isError || isCustomError) {
      oursOnOffense = !isPlayerTeamA;
      discHolderId = null;
    }

    final event = MatchStatEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      customStatId: customStatId,
      createdAt: DateTime.now(),
      pointNumber: point,
      scoreA: scoreA,
      scoreB: scoreB,
      oursOnOffense: oursOnOffense,
      playerId: player?.id,
      discHolderId: discHolderId,
      lineupIds: match.isExternalOpponent
          ? activeLineupA
          : [...activeLineupA, ...activeLineupB],
      statValue: type == MatchStatType.custom
          ? customWeight
          : (player == null ? null : repository.settings.statWeightFor(type)),
      description: _descriptionFor(
        match: match,
        type: type,
        player: player,
        previousHolder: previousHolder,
        customLabel: customLabel,
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
    final isPlayerTeamA = match.isExternalOpponent
        ? true
        : !match.teamBRosterIds.contains(player.id);
    final nextOnOffense = !isPlayerTeamA;

    final event = MatchStatEvent(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: MatchStatType.pull,
      createdAt: DateTime.now(),
      pointNumber: lastEvent?.pointNumber ?? 1,
      scoreA: match.scoreA,
      scoreB: match.scoreB,
      oursOnOffense: nextOnOffense,
      playerId: player.id,
      discHolderId: lastEvent?.discHolderId,
      lineupIds: match.isExternalOpponent
          ? match.teamAIds
          : [...match.teamAIds, ...match.teamBIds],
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
      oursOnOffense: nextOnOffense,
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
        lineupIds: match.isExternalOpponent
            ? match.teamAIds
            : [...match.teamAIds, ...match.teamBIds],
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
          lineupIds: match.isExternalOpponent
              ? match.teamAIds
              : [...match.teamAIds, ...match.teamBIds],
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

    final lastLineup = last?.lineupIds ?? <String>[];
    if (match.isExternalOpponent) {
      match.teamAIds = lastLineup;
      match.teamBIds = [];
    } else {
      match.teamAIds = lastLineup
          .where((id) => match.teamARosterIds.contains(id))
          .toList();
      match.teamBIds = lastLineup
          .where((id) => match.teamBRosterIds.contains(id))
          .toList();
    }

    match
      ..scoreA = last?.scoreA ?? 0
      ..scoreB = last?.scoreB ?? 0
      ..statEvents = events;
    await repository.upsertMatch(match);
  }

  Future<void> updateLineup(
    ScrimmageMatch match,
    List<String> playerIdsA,
    List<String> playerIdsB,
    bool nextOnOffense,
    EloRepository repository,
  ) async {
    if (match.statEvents.isEmpty) return;
    final last = match.statEvents.last;
    match
      ..teamAIds = playerIdsA
      ..teamBIds = playerIdsB
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
          lineupIds: match.isExternalOpponent
              ? playerIdsA
              : [...playerIdsA, ...playerIdsB],
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
    final last = match.statEvents.lastOrNull;
    final isInjuredTeamA = match.isExternalOpponent
        ? true
        : match.teamARosterIds.contains(injured.id);

    if (isInjuredTeamA) {
      if (!match.teamAIds.contains(injured.id)) return;
      final newLineup = match.teamAIds
          .map((id) => id == injured.id ? replacement.id : id)
          .toList();
      match.teamAIds = newLineup;
    } else {
      if (!match.teamBIds.contains(injured.id)) return;
      final newLineup = match.teamBIds
          .map((id) => id == injured.id ? replacement.id : id)
          .toList();
      match.teamBIds = newLineup;
    }

    final nextDiscHolderId = last?.discHolderId == injured.id
        ? replacement.id
        : last?.discHolderId;

    final activeLineupA = match.teamAIds;
    final activeLineupB = match.teamBIds;

    match.statEvents = [
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
        lineupIds: match.isExternalOpponent
            ? activeLineupA
            : [...activeLineupA, ...activeLineupB],
        description: '${injured.name} infortunio · entra ${replacement.name}',
      ),
    ];
    await repository.upsertMatch(match);
  }

  String _descriptionFor({
    required MatchStatType type,
    ScrimmageMatch? match,
    Player? player,
    Player? previousHolder,
    String? customLabel,
  }) {
    if (type == MatchStatType.custom && customLabel != null) {
      return player == null ? customLabel : '${player.name} · $customLabel';
    }
    final isTraining = match != null && !match.isExternalOpponent;
    if (type == MatchStatType.pass || type == MatchStatType.huck) {
      final receiver = player?.name ?? 'ricevitore';
      final thrower = previousHolder?.name ?? 'Disco';
      return '$thrower · ${type.label} verso $receiver';
    }
    if (type == MatchStatType.catchError && player != null) {
      return '${player.name} · Receive error';
    }
    if (type == MatchStatType.opponentError) {
      return isTraining
          ? 'Throwaway ${match.teamBName}'
          : 'Throwaway avversario';
    }
    if (type == MatchStatType.goal) {
      return isTraining ? 'Meta ${match.teamAName}' : 'Meta nostra';
    }
    if (type == MatchStatType.opponentGoal) {
      return isTraining ? 'Meta ${match.teamBName}' : 'Meta avversaria';
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
