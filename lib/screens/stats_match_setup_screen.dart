import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../components/shared/sport_screen_shell.dart';
import '../components/match_form/form_nav_button.dart';
import '../components/stats_match_setup/match_settings_step.dart';
import '../components/stats_match_setup/point_start_selector.dart';
import '../components/stats_match_setup/roster_picker.dart';
import '../components/stats_match_setup/stats_selection_step.dart';
import '../components/stats_match_setup/stats_setup_step_header.dart';
import '../model/player.dart';
import '../providers/elo_providers.dart';
import '../model/stats_match_setup_state.dart';
import '../providers/stats_match_setup_provider.dart';

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
  }

  @override
  void dispose() {
    _opponentController.dispose();
    _teamController.dispose();
    _tournamentController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsMatchSetupProvider);
    final notifier = ref.read(statsMatchSetupProvider.notifier);
    final players = ref.watch(rankedPlayersProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SportScreenShell(
        title: 'Stats match',
        subtitle: switch (state.step) {
          0 => 'Informazioni generali',
          1 => 'Presenti alla partita',
          2 => 'Statistiche da tracciare',
          _ => 'Selezione linea',
        },
        showBackButton: true,
        child: Column(
          spacing: 14,
          children: [
            StatsSetupStepHeader(step: state.step),
            if (state.step == 0)
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
              )
            else if (state.step == 1)
              RosterPicker(
                title: 'Presenti',
                players: _sortedPlayers(
                  players,
                  state.startOnOffense,
                  state.presentPlayerIds,
                ),
                selectedIds: state.presentPlayerIds,
                minimum: state.teamSize,
                preferredLine: state.startOnOffense
                    ? PlayerLinePreference.offense
                    : PlayerLinePreference.defense,
                onToggle: notifier.togglePresentPlayer,
              )
            else if (state.step == 2)
              StatsSelectionStep(
                enabledStatTypes: state.enabledStatTypes,
                onToggleStat: notifier.toggleStat,
              )
            else
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
              padding: const EdgeInsets.only(top: 4), // Adjust spacing
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
                      label: state.step == 3 ? 'Start' : 'Avanti',
                      onPressed: () {
                        if (state.step == 1 &&
                            state.presentPlayerIds.length < state.teamSize) {
                          _showMissingPresentPlayersMessage(state.teamSize);
                          return;
                        }
                        if (state.step < 3) {
                          notifier.setStep(state.step + 1);
                        } else {
                          _tryStart(state, notifier);
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
      final bySelected = (selectedIds.contains(b.id) ? 1 : 0).compareTo(
        selectedIds.contains(a.id) ? 1 : 0,
      );
      if (bySelected != 0) return bySelected;
      return a.name.compareTo(b.name);
    });
    return sorted;
  }
}
