import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/src/features/matches/presentation/match_form/form_nav_button.dart';
import 'package:skrim/src/features/matches/presentation/match_form/presence_step.dart';
import 'package:skrim/src/features/matches/presentation/match_form/score_step.dart';
import 'package:skrim/src/features/matches/presentation/match_form/setup_step.dart';
import 'package:skrim/src/features/matches/presentation/match_form/step_header.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';
import 'package:skrim/src/features/matches/application/matches_providers.dart';
import 'package:skrim/src/features/matches/application/recent_match_team.dart';
import 'package:skrim/src/features/matches/domain/match_form_state.dart';
import 'package:skrim/src/features/matches/application/match_form_provider.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';

class MatchFormScreen extends ConsumerStatefulWidget {
  const MatchFormScreen({super.key, this.match, this.matchId});

  final ScrimmageMatch? match;
  final String? matchId;

  @override
  ConsumerState<MatchFormScreen> createState() => _MatchFormScreenState();
}

class _MatchFormScreenState extends ConsumerState<MatchFormScreen> {
  late final TextEditingController _teamANameController;
  late final TextEditingController _teamBNameController;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(matchFormProvider(widget.matchId));
    _teamANameController = TextEditingController(text: initialState.teamAName);
    _teamBNameController = TextEditingController(text: initialState.teamBName);

    _teamANameController.addListener(() {
      ref
          .read(matchFormProvider(widget.matchId).notifier)
          .updateTeamAName(_teamANameController.text);
    });
    _teamBNameController.addListener(() {
      ref
          .read(matchFormProvider(widget.matchId).notifier)
          .updateTeamBName(_teamBNameController.text);
    });
  }

  @override
  void dispose() {
    _teamANameController.dispose();
    _teamBNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchFormProvider(widget.matchId));
    final notifier = ref.read(matchFormProvider(widget.matchId).notifier);

    // Listen for state changes (e.g. mode changes or regeneration) to update controller values.
    ref.listen<MatchFormState>(matchFormProvider(widget.matchId), (
      previous,
      next,
    ) {
      if (_teamANameController.text != next.teamAName) {
        _teamANameController.text = next.teamAName;
      }
      if (_teamBNameController.text != next.teamBName) {
        _teamBNameController.text = next.teamBName;
      }
    });

    final players = ref.watch(rankedPlayersProvider);
    final recentTeams = ref.watch(recentMatchTeamsProvider);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SportScreenShell(
        title: widget.matchId == null && widget.match == null
            ? 'New match'
            : 'Edit match',
        subtitle: 'Setup scrimmage',
        child: Column(
          spacing: 14,
          children: [
            const SportBackButton(),
            StepHeader(step: state.step),
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ), // Adjust spacing: 14 + 2 = 16 total
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(state.step),
                  child: _buildStep(state, notifier, players, recentTeams),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 4,
              ), // Adjust spacing: 14 + 4 = 18 total
              child: GlassDecoration(
                radius: 22,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: FormNavButton(
                          label: state.step == 0 ? 'Annulla' : 'Indietro',
                          outlined: true,
                          onPressed: state.step == 0
                              ? () => _close(context)
                              : notifier.prevStep,
                        ),
                      ),
                      Expanded(
                        child: FormNavButton(
                          label: state.step == 3 ? 'Salva' : 'Avanti',
                          onPressed: _canContinue(state)
                              ? () => _continue(context, state, notifier)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(
    MatchFormState state,
    MatchFormNotifier notifier,
    List<Player> players,
    List<RecentMatchTeam> recentTeams,
  ) {
    return switch (state.step) {
      0 => SetupStep(
        teamSize: state.teamSize,
        offenseVsDefense: state.offenseVsDefense,
        teamANameController: _teamANameController,
        teamBNameController: _teamBNameController,
        onTeamSizeChanged: notifier.updateTeamSize,
        onModeChanged: notifier.updateMode,
        onRegenerateNames: notifier.regenerateNames,
      ),
      1 => PresenceStep(
        title: state.teamAName.trim().isEmpty ? 'Squadra A' : state.teamAName,
        description: 'Segna tutti i presenti della prima squadra.',
        count: state.teamAIds.length,
        minimum: state.teamSize,
        suggestedLine: state.offenseVsDefense
            ? GameLine.offense
            : null,
        players: players,
        recentTeams: recentTeams,
        selectedIds: state.teamAIds,
        disabledIds: state.teamBIds,
        onChanged: notifier.toggleTeamA,
        onApplyRecentTeam: (team) =>
            notifier.applyRecentTeam(team, toTeamA: true),
      ),
      2 => PresenceStep(
        title: state.teamBName.trim().isEmpty ? 'Squadra B' : state.teamBName,
        description: 'Segna tutti i presenti della seconda squadra.',
        count: state.teamBIds.length,
        minimum: state.teamSize,
        suggestedLine: state.offenseVsDefense
            ? GameLine.defense
            : null,
        players: players,
        recentTeams: recentTeams,
        selectedIds: state.teamBIds,
        disabledIds: state.teamAIds,
        onChanged: notifier.toggleTeamB,
        onApplyRecentTeam: (team) =>
            notifier.applyRecentTeam(team, toTeamA: false),
      ),
      _ => ScoreStep(
        scoreA: state.scoreA,
        scoreB: state.scoreB,
        onScoreAChanged: notifier.updateScoreA,
        onScoreBChanged: notifier.updateScoreB,
        teamSize: state.teamSize,
        teamALabel: state.teamAName.trim().isEmpty
            ? 'Squadra A'
            : state.teamAName,
        teamBLabel: state.teamBName.trim().isEmpty
            ? 'Squadra B'
            : state.teamBName,
        teamACount: state.teamAIds.length,
        teamBCount: state.teamBIds.length,
      ),
    };
  }

  bool _canContinue(MatchFormState state) {
    return switch (state.step) {
      0 => true,
      1 => state.teamAIds.length >= state.teamSize,
      2 => state.teamBIds.length >= state.teamSize,
      _ =>
        state.teamAIds.length >= state.teamSize &&
            state.teamBIds.length >= state.teamSize,
    };
  }

  void _continue(
    BuildContext context,
    MatchFormState state,
    MatchFormNotifier notifier,
  ) {
    if (state.step < 3) {
      notifier.nextStep();
      return;
    }
    _save(context, notifier);
  }

  Future<void> _save(BuildContext context, MatchFormNotifier notifier) async {
    await notifier.save(widget.matchId);
    if (!context.mounted) return;
    _close(context);
  }

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.matches);
    }
  }
}
