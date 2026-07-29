import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/firebase/data/firestore_skrim_repository.dart';
import 'package:skrim/src/features/matches/application/match_provider.dart';

import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/live_stats/application/live_stats_service.dart';
import 'package:skrim/src/features/live_stats/domain/live_match_stats_summary.dart';
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
import 'package:skrim/src/features/players/application/player_providers.dart';

class LiveStatsScreen extends ConsumerStatefulWidget {
  const LiveStatsScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<LiveStatsScreen> createState() => _LiveStatsScreenState();
}

class _LiveStatsScreenState extends ConsumerState<LiveStatsScreen> {
  String _selectedTeamTab = 'teamA';
  String? _lastLineSelectionPromptKey;
  bool _lineSelectionOpen = false;
  bool _livePresenceJoined = false;
  String? _autoConfirmedPendingId;
  String? _joinedMatchId;
  FirestoreSkrimRepository? _joinedRepository;
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
    final matchId = _joinedMatchId;
    final repository = _joinedRepository;
    if (matchId != null && repository != null) {
      unawaited(LiveStatsService.instance.leaveLiveStats(matchId, repository));
    }
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
    final repository = ref.watch(firestoreSkrimRepositoryProvider);
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
    if (!_livePresenceJoined) {
      _livePresenceJoined = true;
      _joinedMatchId = match.id;
      _joinedRepository = repository;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(LiveStatsService.instance.enterLiveStats(match, repository));
      });
    }
    if (match.isFinished) {
      return Scaffold(
        body: SportScreenShell(
          title: 'Live stats',
          subtitle: 'Partita salvata',
          child: SportEmptyState(
            icon: FIcons.lock,
            title: 'Partita chiusa',
            message:
                'Questa partita e stata salvata e non puo piu essere aperta live.',
            action: SportActionButton(
              label: 'Vai al dettaglio',
              icon: FIcons.arrowRight,
              onPressed: () => context.go(AppRoutes.matchDetail(match.id)),
            ),
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

        Future<void> showFinalStatsAndExit() async {
          await FinalStatsSheet.show(context, match, playersById);
          if (context.mounted) {
            context.go(AppRoutes.matchDetail(match.id));
          }
        }

        Future<void> triggerFinishMatch() async {
          final applied = await service.finishMatch(match, repository);
          if (applied && context.mounted) {
            await showFinalStatsAndExit();
          }
        }

        final pending = match.pendingAction;
        if (pending != null &&
            !service.requiresSharedConfirmation(match) &&
            _autoConfirmedPendingId != pending.id) {
          _autoConfirmedPendingId = pending.id;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            final res = await service.confirmPendingAction(
              match,
              playersById: playersById,
              repository: repository,
              settings: settings,
            );
            if (!context.mounted) return;
            if (pending.kind == 'finish' && res?.finished == true) {
              await showFinalStatsAndExit();
            } else if (res?.finished == true) {
              await triggerFinishMatch();
            }
          });
        }

        Future<void> confirmSaveAndClose() async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Salvare e chiudere la partita?'),
              content: const Text(
                'Dopo il salvataggio la partita sara chiusa e non potra piu essere aperta in modalita live.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annulla'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Salva'),
                ),
              ],
            ),
          );
          if (confirmed != true || !context.mounted) return;
          await service.saveAndFinishMatch(match, repository);
          if (context.mounted) {
            context.go(AppRoutes.matchDetail(match.id));
          }
        }

        Future<void> triggerShowLineSelection(bool nextOnOffense) async {
          if (_lineSelectionOpen || match.pendingAction != null) return;
          final allPlayers = ref
              .read(rankedPlayersProvider)
              .where((player) => match.presentPlayerIds.contains(player.id))
              .toList();
          _lineSelectionOpen = true;
          try {
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
          } finally {
            _lineSelectionOpen = false;
          }
        }

        if (_lineSelectionOpen && match.pendingAction != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted || !_lineSelectionOpen) return;
            Navigator.of(context).maybePop();
          });
        }
        if (match.pendingAction?.kind == 'lineup') {
          _lastLineSelectionPromptKey = null;
        }

        final needsLineSelection = match.isExternalOpponent
            ? match.teamAIds.isEmpty
            : match.teamAIds.isEmpty || match.teamBIds.isEmpty;
        final lineSelectionPromptKey =
            '${match.scoreA}-${match.scoreB}-${lastEvent?.pointNumber ?? 1}-${lastEvent?.oursOnOffense ?? true}';
        if (needsLineSelection &&
            match.pendingAction == null &&
            activePause == null &&
            !match.isFinished &&
            !_lineSelectionOpen &&
            _lastLineSelectionPromptKey != lineSelectionPromptKey) {
          _lastLineSelectionPromptKey = lineSelectionPromptKey;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
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
                      if (match.pendingAction != null) return;
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
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.25,
                colors: AppColors.sportBackgroundGradient(context),
                stops: const [0, 0.46, 1],
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
                                color: AppColors.sportElevated(context)
                                    .withValues(
                                      alpha: AppColors.isDark(context)
                                          ? 0.42
                                          : 1,
                                    ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.sportBorder(context),
                                ),
                              ),
                              child: Icon(
                                FIcons.chevronLeft,
                                color: AppColors.sportForeground(context),
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
                              color: AppColors.sportForeground(context),
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
                          onTap: confirmSaveAndClose,
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
                              repository,
                              settings,
                            )
                          : null,
                    ),
                    if (match.pendingAction != null &&
                        service.requiresSharedConfirmation(match))
                      _PendingLiveActionPanel(
                        match: match,
                        playersById: playersById,
                        onConfirm: () async {
                          final pending = match.pendingAction;
                          if (pending == null) return;
                          final res = await service.confirmPendingAction(
                            match,
                            playersById: playersById,
                            repository: repository,
                            settings: settings,
                          );
                          if (!context.mounted) return;
                          if (pending.kind == 'finish') {
                            if (res?.finished == true) {
                              await showFinalStatsAndExit();
                            }
                            return;
                          }
                          if (res == null) return;
                          if (res.finished) {
                            final applied = await service.proposeFinishMatch(
                              match,
                              repository,
                            );
                            if (applied && context.mounted) {
                              await showFinalStatsAndExit();
                            }
                            return;
                          }
                          if (res.halfTimeDue && context.mounted) {
                            await HalfTimePrompt.show(
                              context,
                              service,
                              match,
                              repository,
                              settings,
                            );
                          }
                        },
                        onCancel: () =>
                            service.cancelPendingAction(match, repository),
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
                                settings,
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
                    if (activePause == null && match.pendingAction == null)
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
                            ? () => service.proposeStatAction(
                                match,
                                type: MatchStatType.timeout,
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

class _PendingLiveActionPanel extends StatelessWidget {
  const _PendingLiveActionPanel({
    required this.match,
    required this.playersById,
    required this.onConfirm,
    required this.onCancel,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onCancel;

  @override
  Widget build(BuildContext context) {
    final pending = match.pendingAction;
    if (pending == null) return const SizedBox.shrink();
    final userId = _currentUserId();
    final confirmed = pending.confirmedBy(userId);
    final isCreator = pending.createdByUserId == userId;
    final requiredConfirmations =
        LiveStatsService.instance.requiresSharedConfirmation(match) ? 2 : 1;
    final label = switch (pending.kind) {
      'lineup' => 'nuova linea',
      'finish' => 'fine partita',
      _ => pending.statType?.label ?? 'azione',
    };
    final lineupSummary = pending.kind == 'lineup'
        ? '${_lineupSummary(pending.teamAIds, pending.teamBIds)} · ${pending.confirmedByUserIds.length}/$requiredConfirmations'
        : null;
    final subtitle = confirmed
        ? 'Hai gia confermato. In attesa degli altri utenti.'
        : 'Conferma per applicare l evento live.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.violetLight.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 10,
          children: [
            Icon(
              FIcons.userCheck,
              color: AppColors.sportForeground(context),
              size: 18,
            ),
            Expanded(
              child: Column(
                spacing: 2,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pending.createdByLabel} propone: $label',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    lineupSummary ??
                        '$subtitle ${pending.confirmedByUserIds.length}/$requiredConfirmations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            if (isCreator)
              _PendingActionButton(
                label: 'Annulla',
                onTap: onCancel,
                muted: true,
              ),
            _PendingActionButton(
              label: confirmed ? 'Confermato' : 'Conferma',
              onTap: confirmed ? null : onConfirm,
            ),
          ],
        ),
      ),
    );
  }

  String _lineupSummary(List<String> teamAIds, List<String> teamBIds) {
    String names(List<String> ids) {
      return ids
          .map((id) => playersById[id]?.name)
          .whereType<String>()
          .join(', ');
    }

    final teamA = names(teamAIds);
    final teamB = names(teamBIds);
    if (match.isExternalOpponent) {
      return teamA.isEmpty ? 'Linea proposta vuota' : teamA;
    }
    return '${match.teamAName}: ${teamA.isEmpty ? '-' : teamA} · ${match.teamBName}: ${teamB.isEmpty ? '-' : teamB}';
  }
}

String _currentUserId() {
  try {
    return FirebaseAuth.instance.currentUser?.uid ?? 'local-user';
  } catch (_) {
    return 'local-user';
  }
}

class _PendingActionButton extends StatelessWidget {
  const _PendingActionButton({
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  final String label;
  final Future<void> Function()? onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? () => onTap?.call() : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: muted
              ? AppColors.white.withValues(alpha: 0.08)
              : AppColors.violetLight.withValues(alpha: enabled ? 0.28 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.sportForeground(context).withValues(alpha: 0.14),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: enabled ? AppColors.white : AppColors.sportMutedText,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
