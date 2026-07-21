import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:trio/src/features/matches/application/match_provider.dart';

import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/live_stats/application/live_stats_service.dart';
import 'package:trio/src/features/live_stats/domain/live_match_stats_summary.dart';
import 'active_pause.dart';
import 'bottom_actions.dart';
import 'final_stats_sheet.dart';
import 'goal_recording_handler.dart';
import 'half_time_prompt.dart';
import 'injury_substitution_sheet.dart';
import 'last_action_bar.dart';
import 'legend_modal_bottom_sheet.dart';
import 'line_selection_sheet.dart';
import 'live_score_header.dart';
import 'pause_panel.dart';
import 'player_stat_row.dart';
import 'pull_sheet.dart';
import 'round_header_button.dart';
import 'team_tab_header.dart';
import 'package:trio/src/features/players/application/player_providers.dart';

class LiveStatsScreen extends ConsumerStatefulWidget {
  const LiveStatsScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<LiveStatsScreen> createState() => _LiveStatsScreenState();
}

class _LiveStatsScreenState extends ConsumerState<LiveStatsScreen> {
  String _selectedTeamTab = 'teamA';
  bool _firstLoadChecked = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _selectedTeamTab == 'teamA' ? 0 : 1,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchDetailsProvider(widget.matchId));
    if (match == null) {
      return const Scaffold(
        body: SportScreenShell(
          title: 'Live stats',
          subtitle: 'Match not found',
          child: SportEmptyState(
            icon: FIcons.searchX,
            title: 'Partita non trovata',
            message: 'Non riesco a caricare il match selezionato.',
          ),
        ),
      );
    }

    final service = LiveStatsService.instance;
    final repository = ref.watch(firestoreTrioRepositoryProvider);
    final settings = ref.watch(appSettingsProvider);
    if (repository == null) {
      return const Scaffold(
        body: SportScreenShell(
          title: 'Live stats',
          subtitle: 'Firebase non pronto',
          child: SportEmptyState(
            icon: FIcons.cloudOff,
            title: 'Firebase non disponibile',
            message: 'Accedi di nuovo per registrare statistiche live.',
          ),
        ),
      );
    }

    return StreamBuilder<DateTime>(
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final textTheme = Theme.of(context).textTheme;
        final playersById = {
          for (final player in ref.watch(rankedPlayersProvider))
            player.id: player,
        };

        final lastEvent = match.statEvents.isEmpty
            ? null
            : match.statEvents.last;
        final point = lastEvent?.pointNumber ?? 1;
        final oursOnOffense = lastEvent?.oursOnOffense ?? true;
        final discHolderId = lastEvent?.discHolderId;
        final discHolder = discHolderId == null
            ? null
            : playersById[discHolderId];
        final timeoutRemaining = service.activeCountdown(
          match,
          MatchStatType.timeout,
          match.timeoutSeconds,
          now,
        );
        final halfTimeRemaining = service.activeCountdown(
          match,
          MatchStatType.halfTime,
          match.halfTimeSeconds,
          now,
        );
        final halfTimeDue = service.isHalfTimeDue(match, now);
        final activePause = halfTimeRemaining != null
            ? ActivePause(
                type: MatchStatType.halfTime,
                endType: MatchStatType.halfTimeEnd,
                title: 'Half time',
                remaining: halfTimeRemaining,
                nextOnOffense: oursOnOffense,
              )
            : timeoutRemaining != null
            ? ActivePause(
                type: MatchStatType.timeout,
                endType: MatchStatType.timeoutEnd,
                title: 'Timeout',
                remaining: timeoutRemaining,
                nextOnOffense: oursOnOffense,
              )
            : null;
        final summary = LiveMatchStatsSummary.from(match, playersById);

        Future<void> triggerFinishMatch() async {
          await service.finishMatch(match, repository);
          if (context.mounted) {
            await FinalStatsSheet.show(context, match, playersById);
            if (context.mounted) {
              context.go(AppRoutes.matchDetail(match.id));
            }
          }
        }

        Future<void> triggerShowLineSelection(bool nextOnOffense) async {
          final allPlayers = ref
              .read(rankedPlayersProvider)
              .where((player) => match.presentPlayerIds.contains(player.id))
              .toList();
          final result = await LineSelectionSheet.show(
            context,
            match: match,
            allPlayers: allPlayers,
            getPointsPlayed: (pid) => service.pointsPlayed(match, pid),
            nextOnOffense: nextOnOffense,
          );
          if (result != null) {
            await service.updateLineup(
              match,
              result.teamAIds.toList(),
              result.teamBIds.toList(),
              nextOnOffense,
              repository,
            );
          }
        }

        if (!_firstLoadChecked && match.teamAIds.isEmpty) {
          _firstLoadChecked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            triggerShowLineSelection(lastEvent?.oursOnOffense ?? true);
          });
        }

        Future<void> triggerInjurySubstitution() async {
          final allPlayers = ref
              .read(rankedPlayersProvider)
              .where((player) => match.presentPlayerIds.contains(player.id))
              .toList();
          final currentPlayersList = match.isExternalOpponent
              ? match.teamAIds.map((id) => playersById[id]).nonNulls.toList()
              : [
                  ...match.teamAIds,
                  ...match.teamBIds,
                ].map((id) => playersById[id]).nonNulls.toList();
          final draft = await InjurySubstitutionSheet.show(
            context,
            currentPlayers: currentPlayersList,
            allPlayers: allPlayers,
          );
          if (draft == null) return;
          await service.replaceInjuredPlayer(
            match,
            injured: draft.injured,
            replacement: draft.replacement,
            oursOnOffense: oursOnOffense,
            repository: repository,
            settings: settings,
          );
        }

        Widget buildPlayerList({
          required List<String> activeIds,
          required bool playerOnOffense,
        }) {
          final listPlayers =
              activeIds.map((id) => playersById[id]).nonNulls.toList()
                ..sort((a, b) {
                  final roleCompare = a.role.index.compareTo(b.role.index);
                  if (roleCompare != 0) return roleCompare;
                  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                });

          return ListView(
            padding: EdgeInsets.zero,
            children: listPlayers
                .map(
                  (player) => PlayerStatRow(
                    player: player,
                    enabledStatTypes: match.enabledStatTypes,
                    enabledCustomStatIds: match.enabledCustomStatIds,
                    oursOnOffense: playerOnOffense,
                    hasDisc: player.id == discHolderId,
                    noDiscHolder: playerOnOffense && discHolderId == null,
                    onEvent: (type, customStatId) async {
                      final res = await service.record(
                        match,
                        type: type,
                        customStatId: customStatId,
                        player: player,
                        playersById: playersById,
                        repository: repository,
                        settings: settings,
                      );
                      if (res.finished) {
                        await triggerFinishMatch();
                      } else if (res.scoredPoint && context.mounted) {
                        if (match.teamAIds.isEmpty) {
                          await triggerShowLineSelection(res.oursOnOffense);
                        }
                      }
                    },
                  ),
                )
                .toList(),
          );
        }

        final defendingActiveIds = oursOnOffense
            ? match.teamBIds
            : match.teamAIds;
        final defendingPlayers = defendingActiveIds
            .map((id) => playersById[id])
            .nonNulls
            .toList();

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.25,
                colors: [
                  AppColors.sportBackgroundStart,
                  AppColors.sportBackgroundMid,
                  AppColors.sportBackgroundEnd,
                ],
                stops: [0, 0.46, 1],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Column(
                  spacing: 8,
                  children: [
                    Row(
                      spacing: 8,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go(AppRoutes.matches),
                          child: SizedBox.square(
                            dimension: 38,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.14,
                                  ),
                                ),
                              ),
                              child: const Icon(
                                FIcons.chevronLeft,
                                color: AppColors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Match vs ${match.teamBName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        RoundHeaderButton(
                          icon: FIcons.info,
                          onTap: () =>
                              LegendModalBottomSheet.show(context, match),
                        ),
                        RoundHeaderButton(
                          icon: FIcons.save,
                          onTap: () =>
                              context.go(AppRoutes.matchDetail(match.id)),
                        ),
                      ],
                    ),
                    LiveScoreHeader(
                      match: match,
                      point: point,
                      oursOnOffense: oursOnOffense,
                      discHolderName: discHolder?.name,
                      matchRemaining: service.remainingMatch(match, now),
                      timeoutRemaining: timeoutRemaining,
                      halfTimeRemaining: halfTimeRemaining,
                      halfTimeDue: halfTimeDue,
                      onHalfTime: halfTimeDue
                          ? () => HalfTimePrompt.show(
                              context,
                              service,
                              match,
                              playersById,
                              repository,
                              settings,
                            )
                          : null,
                    ),
                    if (!match.isExternalOpponent && activePause == null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          spacing: 16,
                          children: [
                            TeamTabHeader(
                              label: match.teamAName,
                              selected: _selectedTeamTab == 'teamA',
                              count: match.teamAIds.length,
                              teamSize: match.teamSize,
                              onTap: () {
                                setState(() => _selectedTeamTab = 'teamA');
                                _pageController.animateToPage(
                                  0,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                            TeamTabHeader(
                              label: match.teamBName,
                              selected: _selectedTeamTab == 'teamB',
                              count: match.teamBIds.length,
                              teamSize: match.teamSize,
                              onTap: () {
                                setState(() => _selectedTeamTab = 'teamB');
                                _pageController.animateToPage(
                                  1,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeInOut,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: activePause != null
                          ? PausePanel(
                              pause: activePause,
                              summary: summary,
                              onSelectLine: () => triggerShowLineSelection(
                                activePause.nextOnOffense,
                              ),
                              onEndPause: () => service.endPause(
                                match,
                                activePause.title,
                                activePause.endType,
                                activePause.nextOnOffense,
                                repository,
                              ),
                            )
                          : match.isExternalOpponent
                          ? buildPlayerList(
                              activeIds: match.teamAIds,
                              playerOnOffense: oursOnOffense,
                            )
                          : PageView(
                              controller: _pageController,
                              onPageChanged: (page) {
                                setState(() {
                                  _selectedTeamTab = page == 0
                                      ? 'teamA'
                                      : 'teamB';
                                });
                              },
                              children: [
                                buildPlayerList(
                                  activeIds: match.teamAIds,
                                  playerOnOffense: oursOnOffense,
                                ),
                                buildPlayerList(
                                  activeIds: match.teamBIds,
                                  playerOnOffense: !oursOnOffense,
                                ),
                              ],
                            ),
                    ),
                    if (activePause == null)
                      BottomActions(
                        oursOnOffense: oursOnOffense,
                        showThrowaway: match.tracks(
                          MatchStatType.opponentError,
                        ),
                        timeoutLabel: 'TIMEOUT',
                        goalLabel: match.isExternalOpponent
                            ? 'GOAL'
                            : 'META ${match.teamAName.toUpperCase()}',
                        opponentGoalLabel: match.isExternalOpponent
                            ? 'META AVV'
                            : 'META ${match.teamBName.toUpperCase()}',
                        opponentErrorLabel: match.isExternalOpponent
                            ? 'THROWAWAY'
                            : 'PALLA PERSA ${match.teamBName.toUpperCase()}',
                        onGoal: () => GoalRecordingHandler.confirmAndRecord(
                          context,
                          service: service,
                          match: match,
                          type: MatchStatType.goal,
                          playersById: playersById,
                          repository: repository,
                          settings: settings,
                          onFinish: triggerFinishMatch,
                          onShowLineSelection: triggerShowLineSelection,
                        ),
                        onOpponentGoal: () =>
                            GoalRecordingHandler.confirmAndRecord(
                              context,
                              service: service,
                              match: match,
                              type: MatchStatType.opponentGoal,
                              playersById: playersById,
                              repository: repository,
                              settings: settings,
                              onFinish: triggerFinishMatch,
                              onShowLineSelection: triggerShowLineSelection,
                            ),
                        onOpponentError: () async {
                          final res = await service.record(
                            match,
                            type: MatchStatType.opponentError,
                            playersById: playersById,
                            repository: repository,
                            settings: settings,
                          );
                          if (res.finished) {
                            await triggerFinishMatch();
                          }
                        },
                        onPull:
                            (!oursOnOffense || !match.isExternalOpponent) &&
                                match.tracks(MatchStatType.pull)
                            ? () async {
                                final draft = await PullSheet.show(
                                  context,
                                  defendingPlayers,
                                );
                                if (draft == null) return;
                                await service.recordPull(
                                  match,
                                  player: draft.player,
                                  durationSeconds: draft.durationSeconds,
                                  inBounds: draft.inBounds,
                                  repository: repository,
                                  settings: settings,
                                );
                              }
                            : null,
                        onTimeout: match.hasTimeouts
                            ? () => service.record(
                                match,
                                type: MatchStatType.timeout,
                                playersById: playersById,
                                repository: repository,
                                settings: settings,
                              )
                            : null,
                        onInjury: triggerInjurySubstitution,
                        onUndo: match.statEvents.length > 1
                            ? () => service.undo(match, repository)
                            : null,
                      ),
                    LastActionBar(match: match, playersById: playersById),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
