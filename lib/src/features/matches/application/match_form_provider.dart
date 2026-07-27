import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/src/constants/app_constants.dart';
import 'package:skrim/src/features/auth/application/rbac_provider.dart';
import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/matches/domain/match_form_state.dart';
import 'matches_providers.dart';
import 'recent_match_team.dart';

class MatchFormNotifier extends Notifier<MatchFormState> {
  final String? arg;
  MatchFormNotifier(this.arg);

  @override
  MatchFormState build() {
    if (arg == null) {
      final names = _randomTeamNames();
      return MatchFormState(
        step: 0,
        teamSize: AppConstants.defaultTeamSize,
        offenseVsDefense: false,
        teamAName: names.$1,
        teamBName: names.$2,
        teamAIds: {},
        teamBIds: {},
        scoreA: 0,
        scoreB: 0,
      );
    }

    final matches = ref.read(matchesProvider);
    ScrimmageMatch? match;
    for (final m in matches) {
      if (m.id == arg) {
        match = m;
        break;
      }
    }
    if (match == null) {
      final names = _randomTeamNames();
      return MatchFormState(
        step: 0,
        teamSize: AppConstants.defaultTeamSize,
        offenseVsDefense: false,
        teamAName: names.$1,
        teamBName: names.$2,
        teamAIds: {},
        teamBIds: {},
        scoreA: 0,
        scoreB: 0,
      );
    }

    return MatchFormState(
      step: 0,
      teamSize: match.teamSize,
      offenseVsDefense: match.offenseVsDefense,
      teamAName: match.teamAName,
      teamBName: match.teamBName,
      teamAIds: match.teamAIds.toSet(),
      teamBIds: match.teamBIds.toSet(),
      scoreA: match.scoreA,
      scoreB: match.scoreB,
    );
  }

  void nextStep() {
    if (state.step < 3) {
      state = state.copyWith(step: state.step + 1);
    }
  }

  void prevStep() {
    if (state.step > 0) {
      state = state.copyWith(step: state.step - 1);
    }
  }

  void updateTeamSize(int size) {
    state = state.copyWith(teamSize: size);
  }

  void updateTeamAName(String name) {
    state = state.copyWith(teamAName: name);
  }

  void updateTeamBName(String name) {
    state = state.copyWith(teamBName: name);
  }

  void regenerateNames() {
    final names = _randomTeamNames();
    state = state.copyWith(teamAName: names.$1, teamBName: names.$2);
  }

  void updateMode(bool offenseVsDefense) {
    state = state.copyWith(offenseVsDefense: offenseVsDefense);
    if (offenseVsDefense) {
      final players = ref.read(rankedPlayersProvider);
      final aIds = players
          .where((p) => p.linePreference == PlayerLinePreference.offense)
          .map((p) => p.id)
          .toSet();
      final bIds = players
          .where((p) => p.linePreference == PlayerLinePreference.defense)
          .map((p) => p.id)
          .toSet();
      state = state.copyWith(
        teamAName: 'Attacco',
        teamBName: 'Difesa',
        teamAIds: aIds,
        teamBIds: bIds,
      );
    } else {
      regenerateNames();
    }
  }

  void toggleTeamA(String id) {
    final a = Set<String>.from(state.teamAIds);
    if (a.contains(id)) {
      a.remove(id);
    } else {
      a.add(id);
    }
    state = state.copyWith(teamAIds: a);
  }

  void toggleTeamB(String id) {
    final b = Set<String>.from(state.teamBIds);
    if (b.contains(id)) {
      b.remove(id);
    } else {
      b.add(id);
    }
    state = state.copyWith(teamBIds: b);
  }

  void applyRecentTeam(RecentMatchTeam team, {required bool toTeamA}) {
    final ids = team.playerIds.toSet();
    final a = Set<String>.from(state.teamAIds);
    final b = Set<String>.from(state.teamBIds);
    if (toTeamA) {
      a.clear();
      a.addAll(ids);
      b.removeAll(ids);
      state = state.copyWith(teamAIds: a, teamBIds: b, teamAName: team.name);
    } else {
      b.clear();
      b.addAll(ids);
      a.removeAll(ids);
      state = state.copyWith(teamAIds: a, teamBIds: b, teamBName: team.name);
    }
  }

  void updateScoreA(int score) {
    state = state.copyWith(scoreA: score);
  }

  void updateScoreB(int score) {
    state = state.copyWith(scoreB: score);
  }

  Future<void> save(String? matchId) async {
    final role = ref.read(currentRoleProvider);
    final permission = matchId == null
        ? AppPermission.createMatch
        : AppPermission.editMatch;
    if (!can(role, permission)) return;
    final repository = ref.read(firestoreSkrimRepositoryProvider);
    if (repository == null) return;
    final matches = ref.read(matchesProvider);
    ScrimmageMatch? originalMatch;
    if (matchId != null) {
      for (final m in matches) {
        if (m.id == matchId) {
          originalMatch = m;
          break;
        }
      }
    }
    final savedMatch = ScrimmageMatch(
      id: matchId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: originalMatch?.createdAt ?? DateTime.now(),
      teamAIds: state.teamAIds.toList(),
      teamBIds: state.teamBIds.toList(),
      scoreA: state.scoreA,
      scoreB: state.scoreB,
      teamSize: state.teamSize,
      offenseVsDefense: state.offenseVsDefense,
      teamAName: state.teamAName.trim().isEmpty
          ? (state.offenseVsDefense ? 'Attacco' : 'Squadra A')
          : state.teamAName,
      teamBName: state.teamBName.trim().isEmpty
          ? (state.offenseVsDefense ? 'Difesa' : 'Squadra B')
          : state.teamBName,
    );

    if (originalMatch != null) {
      savedMatch.statEvents = originalMatch.statEvents;
      savedMatch.division = originalMatch.division;
      savedMatch.matchType = originalMatch.matchType;
      savedMatch.windKmh = originalMatch.windKmh;
      savedMatch.pointsLimit = originalMatch.pointsLimit;
      savedMatch.durationMinutes = originalMatch.durationMinutes;
      savedMatch.hasHalfTime = originalMatch.hasHalfTime;
      savedMatch.halfTimeSeconds = originalMatch.halfTimeSeconds;
      savedMatch.hasTimeouts = originalMatch.hasTimeouts;
      savedMatch.timeoutsPerTeamPerHalf = originalMatch.timeoutsPerTeamPerHalf;
      savedMatch.timeoutSeconds = originalMatch.timeoutSeconds;
      savedMatch.enabledStatTypes = originalMatch.enabledStatTypes;
      savedMatch.enabledCustomStatIds = originalMatch.enabledCustomStatIds;
      savedMatch.eventId = originalMatch.eventId;
      savedMatch.trainingEventId = originalMatch.trainingEventId;
    }

    await repository.upsertMatch(savedMatch);
  }

  (String, String) _randomTeamNames() {
    const names = [
      'Vento',
      'Tuono',
      'Lampo',
      'Onde',
      'Fuoco',
      'Nebbia',
      'Falchi',
      'Comete',
      'Spirali',
      'Scie',
      'Sole',
      'Lune',
    ];
    final seed = DateTime.now().microsecondsSinceEpoch;
    final first = seed % names.length;
    final second =
        (first + 3 + (seed ~/ 7) % (names.length - 1)) % names.length;
    return (
      names[first],
      names[second == first ? (second + 1) % names.length : second],
    );
  }
}

final matchFormProvider =
    NotifierProvider.family<MatchFormNotifier, MatchFormState, String?>(
      MatchFormNotifier.new,
    );
