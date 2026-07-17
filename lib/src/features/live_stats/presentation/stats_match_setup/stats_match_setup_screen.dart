import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/features/matches/presentation/match_form/form_nav_button.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/live_stats/application/stats_match_setup_provider.dart';
import 'package:trio/src/features/live_stats/domain/stats_match_setup_state.dart';
import 'match_settings_step.dart';
import 'point_start_selector.dart';
import 'roster_picker.dart';
import 'setup_step.dart';
import 'stats_selection_step.dart';
import 'stats_setup_step_header.dart';
import 'package:trio/src/features/players/application/player_providers.dart';

class StatsMatchSetupScreen extends ConsumerStatefulWidget {
  const StatsMatchSetupScreen({super.key});

  @override
  ConsumerState<StatsMatchSetupScreen> createState() =>
      _StatsMatchSetupScreenState();
}

class _StatsMatchSetupScreenState extends ConsumerState<StatsMatchSetupScreen> {
  late final TextEditingController _opponentController;
  late final TextEditingController _teamController;
  late final TextEditingController _tournamentController;
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(statsMatchSetupProvider);
    _opponentController = TextEditingController(
      text: initialState.opponentName,
    );
    _teamController = TextEditingController(text: initialState.teamName);
    _tournamentController = TextEditingController(
      text: initialState.tournament,
    );
    _locationController = TextEditingController(text: initialState.location);

    _opponentController.addListener(() {
      ref
          .read(statsMatchSetupProvider.notifier)
          .updateOpponentName(_opponentController.text);
    });
    _teamController.addListener(() {
      ref
          .read(statsMatchSetupProvider.notifier)
          .updateTeamName(_teamController.text);
    });
    _tournamentController.addListener(() {
      ref
          .read(statsMatchSetupProvider.notifier)
          .updateTournament(_tournamentController.text);
    });
    _locationController.addListener(() {
      ref
          .read(statsMatchSetupProvider.notifier)
          .updateLocation(_locationController.text);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stateOfRouter = GoRouterState.of(context);
      final isTraining =
          stateOfRouter.uri.queryParameters['type'] == 'training';
      final allPlayers = ref.read(rankedPlayersProvider);
      ref
          .read(statsMatchSetupProvider.notifier)
          .initializeForMatch(isTraining: isTraining, allPlayers: allPlayers);
      final newState = ref.read(statsMatchSetupProvider);
      _teamController.text = newState.teamName;
      _opponentController.text = newState.opponentName;
    });
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _teamController.dispose();
    _tournamentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  List<SetupStep> _getSteps(StatsMatchSetupState state) {
    if (state.isTrainingMatch) {
      if (state.isAttackVsDefense) {
        return [SetupStep.settings, SetupStep.stats];
      } else {
        return [
          SetupStep.settings,
          SetupStep.rosterA,
          SetupStep.rosterB,
          SetupStep.stats,
        ];
      }
    } else {
      return [
        SetupStep.settings,
        SetupStep.rosterA,
        SetupStep.stats,
        SetupStep.lineup,
      ];
    }
  }

  List<String> _getStepLabels(StatsMatchSetupState state) {
    if (state.isTrainingMatch) {
      if (state.isAttackVsDefense) {
        return ['Info', 'Stats'];
      } else {
        return ['Info', state.teamName, state.opponentName, 'Stats'];
      }
    } else {
      return ['Info', 'Presenti', 'Stats', 'Linea'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsMatchSetupProvider);
    final notifier = ref.read(statsMatchSetupProvider.notifier);
    final players = ref.watch(rankedPlayersProvider);

    ref.listen<StatsMatchSetupState>(statsMatchSetupProvider, (previous, next) {
      if (previous?.teamName != next.teamName &&
          _teamController.text != next.teamName) {
        _teamController.text = next.teamName;
      }
      if (previous?.opponentName != next.opponentName &&
          _opponentController.text != next.opponentName) {
        _opponentController.text = next.opponentName;
      }
    });

    final steps = _getSteps(state);
    final stepLabels = _getStepLabels(state);
    final activeStep = steps[state.step];

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SportScreenShell(
        title: 'Stats match',
        subtitle: switch (activeStep) {
          SetupStep.settings => 'Informazioni generali',
          SetupStep.rosterA =>
            state.isTrainingMatch
                ? 'Roster ${state.teamName}'
                : 'Presenti alla partita',
          SetupStep.rosterB => 'Roster ${state.opponentName}',
          SetupStep.stats => 'Statistiche da tracciare',
          SetupStep.lineup => 'Selezione linea',
        },
        showBackButton: true,
        child: Column(
          spacing: 14,
          children: [
            StatsSetupStepHeader(step: state.step, labels: stepLabels),
            if (activeStep == SetupStep.settings)
              MatchSettingsStep(
                teamController: _teamController,
                opponentController: _opponentController,
                tournamentController: _tournamentController,
                locationController: _locationController,
                division: state.division,
                matchType: state.matchType,
                teamSize: state.teamSize,
                windKmh: state.windKmh,
                pointsLimit: state.pointsLimit,
                durationMinutes: state.durationMinutes,
                hasHalfTime: state.hasHalfTime,
                halfTimeSeconds: state.halfTimeSeconds,
                hasTimeouts: state.hasTimeouts,
                timeoutsPerTeamPerHalf: state.timeoutsPerTeamPerHalf,
                timeoutSeconds: state.timeoutSeconds,
                onDivisionChanged: notifier.updateDivision,
                onMatchTypeChanged: notifier.updateMatchType,
                onTeamSizeChanged: notifier.updateTeamSize,
                onWindChanged: notifier.updateWind,
                onPointsChanged: notifier.updatePoints,
                onDurationChanged: notifier.updateDuration,
                onHalfTimeToggle: notifier.toggleHalfTime,
                onHalfTimeSecondsChanged: notifier.updateHalfTimeSeconds,
                onTimeoutToggle: notifier.toggleTimeouts,
                onTimeoutsPerHalfChanged: notifier.updateTimeoutsPerHalf,
                onTimeoutSecondsChanged: notifier.updateTimeoutSeconds,
                isInternalScrimmage: state.isInternalScrimmage,
                onInternalScrimmageToggle: notifier.toggleInternalScrimmage,
                isTrainingMatch: state.isTrainingMatch,
                isAttackVsDefense: state.isAttackVsDefense,
                onAttackVsDefenseToggle: () =>
                    notifier.toggleAttackVsDefense(players),
              )
            else if (activeStep == SetupStep.rosterA)
              RosterPicker(
                title: state.isTrainingMatch
                    ? 'Roster ${state.teamName}'
                    : 'Presenti',
                players: _sortedPlayers(
                  players,
                  state.startOnOffense,
                  state.isTrainingMatch
                      ? state.teamARosterIds
                      : state.presentPlayerIds,
                ),
                selectedIds: state.isTrainingMatch
                    ? state.teamARosterIds
                    : state.presentPlayerIds,
                minimum: state.teamSize,
                preferredLine: state.startOnOffense
                    ? PlayerLinePreference.offense
                    : PlayerLinePreference.defense,
                onToggle: state.isTrainingMatch
                    ? notifier.toggleTeamARoster
                    : notifier.togglePresentPlayer,
              )
            else if (activeStep == SetupStep.rosterB)
              RosterPicker(
                title: 'Roster ${state.opponentName}',
                players: _sortedPlayers(
                  players
                      .where((p) => !state.teamARosterIds.contains(p.id))
                      .toList(),
                  state.startOnOffense,
                  state.teamBRosterIds,
                ),
                selectedIds: state.teamBRosterIds,
                minimum: state.teamSize,
                preferredLine: state.startOnOffense
                    ? PlayerLinePreference.offense
                    : PlayerLinePreference.defense,
                onToggle: notifier.toggleTeamBRoster,
              )
            else if (activeStep == SetupStep.stats)
              StatsSelectionStep(
                enabledStatTypes: state.enabledStatTypes,
                enabledCustomStatIds: state.enabledCustomStatIds,
                onToggleStat: notifier.toggleStat,
                onToggleCustomStat: notifier.toggleCustomStat,
              )
            else if (activeStep == SetupStep.lineup)
              Column(
                spacing: 14,
                children: [
                  PointStartSelector(
                    startOnOffense: state.startOnOffense,
                    onChanged: notifier.updateStartOnOffense,
                  ),
                  RosterPicker(
                    players: _sortedPlayers(
                      players
                          .where(
                            (player) =>
                                state.presentPlayerIds.contains(player.id),
                          )
                          .toList(),
                      state.startOnOffense,
                      state.selectedPlayerIds,
                    ),
                    selectedIds: state.selectedPlayerIds,
                    minimum: state.teamSize,
                    maximum: state.teamSize,
                    title: 'Linea in campo',
                    preferredLine: state.startOnOffense
                        ? PlayerLinePreference.offense
                        : PlayerLinePreference.defense,
                    onToggle: notifier.togglePlayer,
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: FormNavButton(
                      label: state.step == 0 ? 'Annulla' : 'Indietro',
                      outlined: true,
                      onPressed: () {
                        if (state.step == 0) {
                          context.go(AppRoutes.matches);
                        } else {
                          notifier.setStep(state.step - 1);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: FormNavButton(
                      label: state.step == steps.length - 1
                          ? 'Start'
                          : 'Avanti',
                      onPressed: () {
                        if (activeStep == SetupStep.rosterA) {
                          final count = state.isTrainingMatch
                              ? state.teamARosterIds.length
                              : state.presentPlayerIds.length;
                          if (count < state.teamSize) {
                            _showMissingPresentPlayersMessage(state.teamSize);
                            return;
                          }
                        }
                        if (activeStep == SetupStep.rosterB) {
                          if (state.teamBRosterIds.length < state.teamSize) {
                            _showMissingPresentPlayersMessage(state.teamSize);
                            return;
                          }
                        }
                        if (state.step < steps.length - 1) {
                          notifier.setStep(state.step + 1);
                        } else {
                          if (state.isInternalScrimmage) {
                            _startMatch(notifier);
                          } else {
                            _tryStart(state, notifier);
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _tryStart(StatsMatchSetupState state, StatsMatchSetupNotifier notifier) {
    if (state.selectedPlayerIds.length != state.teamSize) {
      _showMissingPlayersMessage(state.teamSize);
      return;
    }
    _startMatch(notifier);
  }

  Future<void> _startMatch(StatsMatchSetupNotifier notifier) async {
    final matchId = await notifier.startMatch();
    if (!mounted) return;
    context.go(AppRoutes.liveStats(matchId));
  }

  void _showMissingPlayersMessage(int teamSize) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Seleziona $teamSize giocatori in campo.')),
    );
  }

  void _showMissingPresentPlayersMessage(int teamSize) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Segna almeno $teamSize presenti.')));
  }

  List<Player> _sortedPlayers(
    List<Player> players,
    bool startOnOffense,
    Set<String> selectedIds,
  ) {
    final preferred = startOnOffense
        ? PlayerLinePreference.offense
        : PlayerLinePreference.defense;
    final sorted = [...players];
    sorted.sort((a, b) {
      final byLine = (a.linePreference == preferred ? 0 : 1).compareTo(
        b.linePreference == preferred ? 0 : 1,
      );
      if (byLine != 0) return byLine;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }
}
