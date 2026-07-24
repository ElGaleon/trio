import 'package:firebase_auth/firebase_auth.dart';

import 'package:trio/src/features/firebase/data/firestore_trio_repository.dart';
import 'package:trio/src/features/settings/domain/app_settings.dart';
import 'package:trio/src/features/matches/domain/live_pending_action.dart';
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

  Future<void> proposeStatAction(
    ScrimmageMatch match, {
    required MatchStatType type,
    required FirestoreTrioRepository repository,
  }) async {
    final actor = _actor();
    await repository.updateMatchTransaction(match.id, (current) {
      if (current.pendingAction != null) return current;
      current.pendingAction = LivePendingAction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: 'stat',
        statType: type,
        createdAt: DateTime.now(),
        createdByUserId: actor.$1,
        createdByLabel: actor.$2,
        confirmedByUserIds: [actor.$1],
      );
      return current;
    });
  }

  Future<void> proposeFinishMatch(
    ScrimmageMatch match,
    FirestoreTrioRepository repository,
  ) async {
    final actor = _actor();
    await repository.updateMatchTransaction(match.id, (current) {
      if (current.pendingAction != null) return current;
      current.pendingAction = LivePendingAction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: 'finish',
        createdAt: DateTime.now(),
        createdByUserId: actor.$1,
        createdByLabel: actor.$2,
        confirmedByUserIds: [actor.$1],
      );
      return current;
    });
  }

  Future<void> proposeLineup(
    ScrimmageMatch match, {
    required List<String> playerIdsA,
    required List<String> playerIdsB,
    required bool nextOnOffense,
    required FirestoreTrioRepository repository,
  }) async {
    final actor = _actor();
    await repository.updateMatchTransaction(match.id, (current) {
      if (current.pendingAction != null) return current;
      current.pendingAction = LivePendingAction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        kind: 'lineup',
        createdAt: DateTime.now(),
        createdByUserId: actor.$1,
        createdByLabel: actor.$2,
        confirmedByUserIds: [actor.$1],
        teamAIds: playerIdsA,
        teamBIds: playerIdsB,
        nextOnOffense: nextOnOffense,
      );
      return current;
    });
  }

  Future<RecordEventResult?> confirmPendingAction(
    ScrimmageMatch match, {
    required Map<String, Player> playersById,
    required FirestoreTrioRepository repository,
    required AppSettings settings,
  }) async {
    final actor = _actor();
    RecordEventResult? result;
    await repository.updateMatchTransaction(match.id, (current) {
      final pending = current.pendingAction;
      if (pending == null) return current;
      final confirmed = pending.confirm(actor.$1);
      if (confirmed.confirmedByUserIds.length < 2) {
        current.pendingAction = confirmed;
        return current;
      }

      current.pendingAction = null;
      if (confirmed.kind == 'lineup') {
        _applyLineup(
          current,
          confirmed.teamAIds,
          confirmed.teamBIds,
          confirmed.nextOnOffense ?? true,
          actor.$1,
          actor.$2,
        );
        return current;
      }
      if (confirmed.kind == 'finish') {
        _applyFinish(current, actor.$1, actor.$2);
        result = RecordEventResult(
          scoredPoint: false,
          finished: true,
          halfTimeDue: false,
          oursOnOffense: current.statEvents.lastOrNull?.oursOnOffense ?? true,
        );
        return current;
      }
      final type = confirmed.statType;
      if (type == null) return current;
      result = _applyRecord(
        current,
        type: type,
        player: null,
        playersById: playersById,
        settings: settings,
        actorUserId: actor.$1,
        actorLabel: actor.$2,
      );
      return current;
    });
    return result;
  }

  Future<void> cancelPendingAction(
    ScrimmageMatch match,
    FirestoreTrioRepository repository,
  ) async {
    await repository.updateMatchTransaction(match.id, (current) {
      current.pendingAction = null;
      return current;
    });
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
    required FirestoreTrioRepository repository,
    required AppSettings settings,
  }) async {
    late RecordEventResult result;
    final actor = _actor();
    await repository.updateMatchTransaction(match.id, (current) {
      result = _applyRecord(
        current,
        type: type,
        customStatId: customStatId,
        player: player,
        playersById: playersById,
        settings: settings,
        actorUserId: actor.$1,
        actorLabel: actor.$2,
      );
      return current;
    });
    return result;
  }

  RecordEventResult _applyRecord(
    ScrimmageMatch match, {
    required MatchStatType type,
    String? customStatId,
    Player? player,
    required Map<String, Player> playersById,
    required AppSettings settings,
    required String actorUserId,
    required String actorLabel,
  }) {
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
      final customStat = settings.customStats.firstWhere(
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
          : (player == null ? null : settings.statWeightFor(type)),
      createdByUserId: actorUserId,
      createdByLabel: actorLabel,
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
    required FirestoreTrioRepository repository,
    required AppSettings settings,
  }) async {
    final actor = _actor();
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
      statValue: settings.statWeightFor(MatchStatType.pull),
      createdByUserId: actor.$1,
      createdByLabel: actor.$2,
      description:
          '${player.name} · Pull ${durationSeconds}s · ${inBounds ? 'dentro' : 'fuori'}',
    );

    match.statEvents = [...match.statEvents, event];
    await repository.updateMatchTransaction(match.id, (_) => match);

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
    FirestoreTrioRepository repository,
  ) async {
    await proposeStatAction(match, type: endType, repository: repository);
  }

  Future<void> finishMatch(
    ScrimmageMatch match,
    FirestoreTrioRepository repository,
  ) async {
    await proposeFinishMatch(match, repository);
  }

  Future<void> saveAndFinishMatch(
    ScrimmageMatch match,
    FirestoreTrioRepository repository,
  ) async {
    final actor = _actor();
    await repository.updateMatchTransaction(match.id, (current) {
      current.pendingAction = null;
      _applyFinish(current, actor.$1, actor.$2);
      return current;
    });
  }

  Future<void> undo(
    ScrimmageMatch match,
    FirestoreTrioRepository repository,
  ) async {
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
    await repository.updateMatchTransaction(match.id, (_) => match);
  }

  Future<void> updateLineup(
    ScrimmageMatch match,
    List<String> playerIdsA,
    List<String> playerIdsB,
    bool nextOnOffense,
    FirestoreTrioRepository repository,
  ) async {
    await proposeLineup(
      match,
      playerIdsA: playerIdsA,
      playerIdsB: playerIdsB,
      nextOnOffense: nextOnOffense,
      repository: repository,
    );
  }

  void _applyLineup(
    ScrimmageMatch match,
    List<String> playerIdsA,
    List<String> playerIdsB,
    bool nextOnOffense,
    String actorUserId,
    String actorLabel,
  ) {
    final last = match.statEvents.lastOrNull;
    match
      ..teamAIds = playerIdsA
      ..teamBIds = playerIdsB
      ..statEvents = [
        ...match.statEvents,
        MatchStatEvent(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          type: MatchStatType.lineup,
          createdAt: DateTime.now(),
          pointNumber: last?.pointNumber ?? 1,
          scoreA: match.scoreA,
          scoreB: match.scoreB,
          oursOnOffense: nextOnOffense,
          lineupIds: match.isExternalOpponent
              ? playerIdsA
              : [...playerIdsA, ...playerIdsB],
          createdByUserId: actorUserId,
          createdByLabel: actorLabel,
          description:
              'Linea ${nextOnOffense ? 'attacco' : 'difesa'} selezionata',
        ),
      ];
  }

  void _applyFinish(
    ScrimmageMatch match,
    String actorUserId,
    String actorLabel,
  ) {
    if (match.statEvents.any((event) => event.type == MatchStatType.matchEnd)) {
      return;
    }
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
        createdByUserId: actorUserId,
        createdByLabel: actorLabel,
        description: 'Partita conclusa',
      ),
    ];
  }

  Future<void> replaceInjuredPlayer(
    ScrimmageMatch match, {
    required Player injured,
    required Player replacement,
    required bool oursOnOffense,
    required FirestoreTrioRepository repository,
    required AppSettings settings,
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
        createdByUserId: _actor().$1,
        createdByLabel: _actor().$2,
        description: '${injured.name} infortunio · entra ${replacement.name}',
      ),
    ];
    await repository.updateMatchTransaction(match.id, (_) => match);
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

  (String, String) _actor() {
    User? user;
    try {
      user = FirebaseAuth.instance.currentUser;
    } catch (_) {
      user = null;
    }
    final id = user?.uid ?? 'local-user';
    final label = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : user?.email?.trim().isNotEmpty == true
        ? user!.email!.trim()
        : 'Utente';
    return (id, label);
  }
}
