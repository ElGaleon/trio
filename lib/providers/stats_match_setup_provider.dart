import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/player.dart';
import '../model/scrimmage_match.dart';
import '../model/stats_match_setup_state.dart';
import 'elo_providers.dart';

class StatsMatchSetupNotifier extends Notifier<StatsMatchSetupState> {
  @override
  StatsMatchSetupState build() {
    return StatsMatchSetupState(
      step: 0,
      teamName: 'Noi',
      opponentName: 'Avversari',
      tournament: '',
      location: '',
      division: 'Mixed',
      matchType: 'Classic',
      teamSize: 7,
      windKmh: 0,
      pointsLimit: 15,
      durationMinutes: 80,
      hasHalfTime: true,
      halfTimeSeconds: 300,
      hasTimeouts: true,
      timeoutsPerTeamPerHalf: 2,
      timeoutSeconds: 90,
      enabledStatTypes: MatchStatType.defaultEnabled.toSet(),
      presentPlayerIds: {},
      startOnOffense: true,
      selectedPlayerIds: {},
      isInternalScrimmage: false,
      teamARosterIds: {},
      teamBRosterIds: {},
      isTrainingMatch: false,
      isAttackVsDefense: false,
    );
  }

  void initializeForMatch({required bool isTraining, required List<Player> allPlayers}) {
    state = StatsMatchSetupState(
      step: 0,
      teamName: isTraining ? 'Chiari' : 'Noi',
      opponentName: isTraining ? 'Scuri' : 'Avversari',
      tournament: '',
      location: '',
      division: 'Mixed',
      matchType: isTraining ? 'Allenamento' : 'Classic',
      teamSize: 7,
      windKmh: 0,
      pointsLimit: 15,
      durationMinutes: 80,
      hasHalfTime: !isTraining,
      halfTimeSeconds: 300,
      hasTimeouts: !isTraining,
      timeoutsPerTeamPerHalf: 2,
      timeoutSeconds: 90,
      enabledStatTypes: MatchStatType.defaultEnabled.toSet(),
      presentPlayerIds: {},
      startOnOffense: true,
      selectedPlayerIds: {},
      isInternalScrimmage: isTraining,
      teamARosterIds: {},
      teamBRosterIds: {},
      isTrainingMatch: isTraining,
      isAttackVsDefense: false,
    );
  }

  void toggleAttackVsDefense(List<Player> allPlayers) {
    final nextVal = !state.isAttackVsDefense;
    state = state.copyWith(isAttackVsDefense: nextVal);
    if (nextVal) {
      final a = allPlayers
          .where((p) => p.linePreference == PlayerLinePreference.offense)
          .map((p) => p.id)
          .toSet();
      final b = allPlayers
          .where((p) => p.linePreference == PlayerLinePreference.defense)
          .map((p) => p.id)
          .toSet();
      state = state.copyWith(
        teamARosterIds: a,
        teamBRosterIds: b,
        teamName: 'Attacco',
        opponentName: 'Difesa',
      );
    } else {
      state = state.copyWith(
        teamARosterIds: {},
        teamBRosterIds: {},
        teamName: 'Chiari',
        opponentName: 'Scuri',
      );
    }
  }

  void setStep(int step) => state = state.copyWith(step: step);
  void updateTeamName(String name) => state = state.copyWith(teamName: name);
  void updateOpponentName(String name) =>
      state = state.copyWith(opponentName: name);
  void updateTournament(String val) => state = state.copyWith(tournament: val);
  void updateLocation(String val) => state = state.copyWith(location: val);
  void updateDivision(String val) => state = state.copyWith(division: val);
  void updateMatchType(String val) => state = state.copyWith(matchType: val);
  void updateTeamSize(int val) => state = state.copyWith(teamSize: val);
  void updateWind(int val) => state = state.copyWith(windKmh: val);
  void updatePoints(int val) => state = state.copyWith(pointsLimit: val);
  void updateDuration(int val) => state = state.copyWith(durationMinutes: val);

  void toggleHalfTime() {
    state = state.copyWith(hasHalfTime: !state.hasHalfTime);
  }

  void updateHalfTimeSeconds(int val) {
    state = state.copyWith(halfTimeSeconds: val);
  }

  void toggleTimeouts() {
    state = state.copyWith(hasTimeouts: !state.hasTimeouts);
  }

  void updateTimeoutsPerHalf(int val) {
    state = state.copyWith(timeoutsPerTeamPerHalf: val);
  }

  void updateTimeoutSeconds(int val) {
    state = state.copyWith(timeoutSeconds: val);
  }

  void updateStartOnOffense(bool val) {
    state = state.copyWith(startOnOffense: val);
  }

  void toggleInternalScrimmage() {
    state = state.copyWith(isInternalScrimmage: !state.isInternalScrimmage);
    if (state.isInternalScrimmage) {
      state = state.copyWith(
        teamName: 'Light',
        opponentName: 'Dark',
      );
    } else {
      state = state.copyWith(
        teamName: 'Noi',
        opponentName: 'Avversari',
      );
    }
  }

  void toggleTeamARoster(String id) {
    final a = Set<String>.from(state.teamARosterIds);
    final b = Set<String>.from(state.teamBRosterIds);
    if (a.contains(id)) {
      a.remove(id);
    } else {
      a.add(id);
      b.remove(id);
    }
    state = state.copyWith(teamARosterIds: a, teamBRosterIds: b);
  }

  void toggleTeamBRoster(String id) {
    final a = Set<String>.from(state.teamARosterIds);
    final b = Set<String>.from(state.teamBRosterIds);
    if (b.contains(id)) {
      b.remove(id);
    } else {
      b.add(id);
      a.remove(id);
    }
    state = state.copyWith(teamARosterIds: a, teamBRosterIds: b);
  }

  void toggleStat(MatchStatType type) {
    final list = Set<MatchStatType>.from(state.enabledStatTypes);
    if (list.contains(type)) {
      list.remove(type);
    } else {
      list.add(type);
    }
    state = state.copyWith(enabledStatTypes: list);
  }

  void togglePlayer(String id) {
    final ids = Set<String>.from(state.selectedPlayerIds);
    if (ids.contains(id)) {
      ids.remove(id);
    } else if (ids.length < state.teamSize &&
        state.presentPlayerIds.contains(id)) {
      ids.add(id);
    }
    state = state.copyWith(selectedPlayerIds: ids);
  }

  void togglePresentPlayer(String id) {
    final presentIds = Set<String>.from(state.presentPlayerIds);
    final selectedIds = Set<String>.from(state.selectedPlayerIds);
    if (presentIds.contains(id)) {
      presentIds.remove(id);
      selectedIds.remove(id);
    } else {
      presentIds.add(id);
    }
    state = state.copyWith(
      presentPlayerIds: presentIds,
      selectedPlayerIds: selectedIds,
    );
  }

  Future<String> startMatch() async {
    final repository = ref.read(eloRepositoryProvider);
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final opponent = state.opponentName.trim().isEmpty
        ? (state.isInternalScrimmage ? 'Dark' : 'Avversari')
        : state.opponentName.trim();
    final team = state.teamName.trim().isEmpty
        ? (state.isInternalScrimmage ? 'Light' : 'Noi')
        : state.teamName.trim();

    final isInternal = state.isInternalScrimmage;

    final match = ScrimmageMatch(
      id: id,
      createdAt: DateTime.now(),
      teamAIds: isInternal ? const [] : state.selectedPlayerIds.toList(),
      teamBIds: const [],
      scoreA: 0,
      scoreB: 0,
      teamSize: state.teamSize,
      offenseVsDefense: state.isAttackVsDefense,
      teamAName: team,
      teamBName: opponent,
      isExternalOpponent: !isInternal,
      division: state.division,
      tournament: state.tournament.trim(),
      matchType: state.matchType,
      windKmh: state.windKmh,
      pointsLimit: state.pointsLimit,
      durationMinutes: state.durationMinutes,
      location: state.location.trim(),
      hasHalfTime: state.hasHalfTime,
      halfTimeSeconds: state.hasHalfTime ? state.halfTimeSeconds : 0,
      hasTimeouts: state.hasTimeouts,
      timeoutsPerTeamPerHalf: state.hasTimeouts
          ? state.timeoutsPerTeamPerHalf
          : 0,
      timeoutSeconds: state.hasTimeouts ? state.timeoutSeconds : 0,
      presentPlayerIds: isInternal
          ? {...state.teamARosterIds, ...state.teamBRosterIds}.toList()
          : state.presentPlayerIds.toList(),
      teamARosterIds: isInternal
          ? state.teamARosterIds.toList()
          : state.presentPlayerIds.toList(),
      teamBRosterIds: isInternal
          ? state.teamBRosterIds.toList()
          : const [],
      enabledStatTypes: state.enabledStatTypes.toList(),
      statEvents: [
        MatchStatEvent(
          id: '$id-start',
          type: state.startOnOffense
              ? MatchStatType.pass
              : MatchStatType.defense,
          createdAt: DateTime.now(),
          pointNumber: 1,
          scoreA: 0,
          scoreB: 0,
          oursOnOffense: state.startOnOffense,
          discHolderId: null,
          lineupIds: isInternal ? const [] : state.selectedPlayerIds.toList(),
          description: state.location.trim().isEmpty
              ? 'Inizio partita vs $opponent'
              : 'Inizio partita vs $opponent · ${state.location.trim()}',
        ),
      ],
    );

    await repository.upsertMatch(match);
    return id;
  }
}

final statsMatchSetupProvider =
    NotifierProvider.autoDispose<StatsMatchSetupNotifier, StatsMatchSetupState>(
      StatsMatchSetupNotifier.new,
    );
