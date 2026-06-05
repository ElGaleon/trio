import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../app_router.dart';
import '../components/shared/app_empty_state.dart';
import '../components/shared/app_header.dart';
import '../components/shared/sport_screen_shell.dart';
import '../components/live_stats/action_buttons.dart';
import '../components/live_stats/bottom_actions.dart';
import '../components/live_stats/live_score_header.dart';
import '../components/live_stats/pause_panel.dart';
import '../components/live_stats/player_stat_row.dart';
import '../components/live_stats/line_selection_modal.dart';
import '../model/player.dart';
import '../model/scrimmage_match.dart';
import '../model/live_stats_models.dart';
import '../providers/elo_providers.dart';
import '../providers/match_provider.dart';
import '../repositories/elo_repository.dart';
import '../service/live_stats_service.dart';
import '../theme/app_colors.dart';

class RoundHeaderButton extends StatelessWidget {
  const RoundHeaderButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 42,
        height: 42,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
          ),
          child: Center(child: Icon(icon, color: AppColors.white, size: 20)),
        ),
      ),
    );
  }
}

class LegendRow extends StatelessWidget {
  const LegendRow({super.key, required this.code, required this.label});

  final String code;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        spacing: 10,
        children: [
          SizedBox(
            width: 44,
            child: StatButton(label: code, onTap: () {}),
          ),
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LastActionBar extends StatelessWidget {
  const LastActionBar({
    super.key,
    required this.match,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final event = match.statEvents.isEmpty ? null : match.statEvents.last;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.32),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            event?.description ?? 'Nessuna azione registrata',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: sportMutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class PullDraft {
  const PullDraft({
    required this.player,
    required this.durationSeconds,
    required this.inBounds,
  });

  final Player player;
  final int durationSeconds;
  final bool inBounds;
}

void showLegend(BuildContext context, ScrimmageMatch match) {
  final enabled = match.enabledStatTypes.toSet();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          decoration: solidPanelDecoration(radius: 28),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (enabled.contains(MatchStatType.pass))
                const LegendRow(code: 'P', label: 'Passaggio'),
              if (enabled.contains(MatchStatType.huck))
                const LegendRow(code: 'H', label: 'Huck'),
              if (enabled.contains(MatchStatType.throwError))
                const LegendRow(code: 'TE', label: 'Throw error'),
              if (enabled.contains(MatchStatType.catchError))
                const LegendRow(code: 'RE', label: 'Receive error'),
              const LegendRow(code: 'G', label: 'Goal'),
              if (enabled.contains(MatchStatType.catchDisc))
                const LegendRow(code: 'C', label: 'Catch / possesso'),
              if (enabled.contains(MatchStatType.block))
                const LegendRow(code: 'B', label: 'Block'),
              if (enabled.contains(MatchStatType.pull))
                const LegendRow(code: 'PU', label: 'Pull dentro/fuori'),
              if (enabled.contains(MatchStatType.stallOut))
                const LegendRow(code: 'S', label: 'Stall out'),
              if (enabled.contains(MatchStatType.openError))
                const LegendRow(code: 'A', label: 'Errore aperto'),
              if (enabled.contains(MatchStatType.deepError))
                const LegendRow(code: 'BU', label: 'Errore sul buco'),
              if (enabled.contains(MatchStatType.resetError))
                const LegendRow(code: 'R', label: 'Errore reset'),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<PullDraft?> showPullSheet(
  BuildContext context,
  List<Player> players,
) async {
  return showModalBottomSheet<PullDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => _PullStopwatchSheet(players: players),
  );
}

class _PullStopwatchSheet extends StatefulWidget {
  const _PullStopwatchSheet({required this.players});

  final List<Player> players;

  @override
  State<_PullStopwatchSheet> createState() => _PullStopwatchSheetState();
}

class _PullStopwatchSheetState extends State<_PullStopwatchSheet> {
  late Player? _selected = widget.players.isEmpty ? null : widget.players.first;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _hasStarted = false;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _start() {
    if (_selected == null) return;
    setState(() {
      _hasStarted = true;
      _stopwatch
        ..reset()
        ..start();
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (mounted) setState(() {});
    });
  }

  void _cancelTimer() {
    setState(() {
      _hasStarted = false;
      _stopwatch
        ..stop()
        ..reset();
    });
    _ticker?.cancel();
  }

  void _save(bool inBounds) {
    final player = _selected;
    if (player == null || !_hasStarted) return;
    _stopwatch.stop();
    _ticker?.cancel();
    final seconds = _stopwatch.elapsed.inMilliseconds / 1000;
    Navigator.pop(
      context,
      PullDraft(
        player: player,
        durationSeconds: seconds.ceil().clamp(1, 999),
        inBounds: inBounds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          decoration: solidPanelDecoration(radius: 28),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 14,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cronometro pull',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                _hasStarted
                    ? 'Ferma il cronometro scegliendo se il pull e rimasto dentro o e uscito.'
                    : 'Seleziona il tiratore e avvia il cronometro quando parte il pull.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: sportMutedText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final player in widget.players)
                        _PullPlayerChip(
                          player: player,
                          selected: _selected?.id == player.id,
                          onTap: _hasStarted
                              ? () {}
                              : () => setState(() => _selected = player),
                        ),
                    ],
                  ),
                ),
              ),
              _PullTimerDisplay(
                elapsed: _stopwatch.elapsed,
                running: _stopwatch.isRunning,
              ),
              if (!_hasStarted)
                GeneralActionButton(
                  label: 'START PULL',
                  icon: FIcons.play,
                  accent: AppColors.violet,
                  onTap: _selected == null ? () {} : _start,
                )
              else
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: GeneralActionButton(
                        label: 'DENTRO',
                        icon: FIcons.check,
                        accent: AppColors.violet,
                        compact: true,
                        onTap: () => _save(true),
                      ),
                    ),
                    Expanded(
                      child: GeneralActionButton(
                        label: 'FUORI',
                        icon: FIcons.x,
                        accent: AppColors.danger,
                        compact: true,
                        onTap: () => _save(false),
                      ),
                    ),
                    SquareActionButton(
                      icon: FIcons.rotateCcw,
                      label: 'Reset',
                      onTap: _cancelTimer,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PullTimerDisplay extends StatelessWidget {
  const _PullTimerDisplay({required this.elapsed, required this.running});

  final Duration elapsed;
  final bool running;

  @override
  Widget build(BuildContext context) {
    final minutes = elapsed.inMinutes;
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final tenths = ((elapsed.inMilliseconds % 1000) ~/ 100).toString();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: running
              ? AppColors.violet
              : AppColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Icon(
              running ? FIcons.timer : FIcons.timerReset,
              color: running ? AppColors.violetLight : sportMutedText,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                '$minutes:$seconds.$tenths',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Text(
              running ? 'LIVE' : 'READY',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: running ? AppColors.violetLight : sportMutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PullPlayerChip extends StatelessWidget {
  const _PullPlayerChip({
    required this.player,
    required this.selected,
    required this.onTap,
  });

  final Player player;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.20)
              : AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          player.name,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

Future<void> showHalfTimePrompt(
  BuildContext context,
  LiveStatsService service,
  ScrimmageMatch match,
  Map<String, Player> playersById,
  EloRepository repository,
) async {
  if (service.hasHalfTimeEvent(match)) return;
  final start = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          decoration: solidPanelDecoration(radius: 28),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                'Half time',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Siete arrivati alla metà partita. Vuoi avviare il countdown ora?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: sportMutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: GeneralActionButton(
                      label: 'SKIP',
                      icon: FIcons.x,
                      accent: AppColors.appDarkElevated,
                      compact: true,
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  Expanded(
                    child: GeneralActionButton(
                      label: 'START',
                      icon: FIcons.play,
                      accent: AppColors.violet,
                      compact: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (start != true) return;
  if (!context.mounted) return;
  await service.record(
    match,
    type: MatchStatType.halfTime,
    playersById: playersById,
    repository: repository,
  );
}

Future<void> showFinalStats(
  BuildContext context,
  ScrimmageMatch match,
  Map<String, Player> playersById,
) async {
  final summary = LiveMatchStatsSummary.from(match, playersById);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.82,
          ),
          decoration: solidPanelDecoration(radius: 28),
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 12,
            children: [
              Text(
                'Match stats',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Expanded(child: StatsSummaryView(summary: summary)),
              GeneralActionButton(
                label: 'CHIUDI',
                icon: FIcons.check,
                accent: AppColors.violet,
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> confirmAndRecordGoal(
  BuildContext context,
  LiveStatsService service,
  ScrimmageMatch match,
  MatchStatType type,
  Map<String, Player> playersById,
  EloRepository repository,
  Future<void> Function() onFinish,
  Future<void> Function(bool nextOnOffense) onShowLineSelection,
) async {
  final nextScoreA = match.scoreA + (type == MatchStatType.goal ? 1 : 0);
  final nextScoreB =
      match.scoreB + (type == MatchStatType.opponentGoal ? 1 : 0);
  final closesMatch =
      nextScoreA >= match.pointsLimit || nextScoreB >= match.pointsLimit;
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.transparent,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Container(
          decoration: solidPanelDecoration(radius: 28),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                closesMatch ? 'Conferma fine match' : 'Conferma meta',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                closesMatch
                    ? 'Il punteggio diventa $nextScoreA - $nextScoreB and la partita arriva al limite di ${match.pointsLimit}.'
                    : 'Il punteggio diventa $nextScoreA - $nextScoreB. Confermi?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: sportMutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: GeneralActionButton(
                      label: 'ANNULLA',
                      icon: FIcons.x,
                      accent: AppColors.appDarkElevated,
                      compact: true,
                      onTap: () => Navigator.pop(context, false),
                    ),
                  ),
                  Expanded(
                    child: GeneralActionButton(
                      label: 'CONFERMA',
                      icon: FIcons.check,
                      accent: AppColors.violet,
                      compact: true,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (confirmed != true) return;
  if (!context.mounted) return;

  final res = await service.record(
    match,
    type: type,
    playersById: playersById,
    repository: repository,
  );
  if (!context.mounted) return;
  if (res.finished) {
    await onFinish();
    return;
  }
  if (res.halfTimeDue) {
    await showHalfTimePrompt(context, service, match, playersById, repository);
  }
  if (!context.mounted) return;
  if (res.scoredPoint && context.mounted) {
    await onShowLineSelection(res.oursOnOffense);
  }
}

class LiveStatsScreen extends ConsumerWidget {
  const LiveStatsScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final match = ref.watch(matchDetailsProvider(matchId));
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
    final repository = ref.read(eloRepositoryProvider);

    return StreamBuilder<DateTime>(
      stream: Stream<DateTime>.periodic(
        const Duration(seconds: 1),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final playersById = {
          for (final player in ref.watch(rankedPlayersProvider))
            player.id: player,
        };
        final players = match.teamAIds
            .map((id) => playersById[id])
            .nonNulls
            .toList();
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
            await showFinalStats(context, match, playersById);
            if (context.mounted) {
              context.go(AppRoutes.matchDetail(match.id));
            }
          }
        }

        Future<void> triggerShowLineSelection(bool nextOnOffense) async {
          final allPlayers = ref.read(rankedPlayersProvider);
          final result = await showLineSelectionSheet(
            context,
            match: match,
            allPlayers: allPlayers,
            getPointsPlayed: (pid) => service.pointsPlayed(match, pid),
            nextOnOffense: nextOnOffense,
          );
          if (result != null && result.length == match.teamSize) {
            await service.updateLineup(
              match,
              result.toList(),
              nextOnOffense,
              repository,
            );
          }
        }

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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                child: Column(
                  spacing: 8,
                  children: [
                    AppHeader(
                      title: 'Match',
                      subtitle: 'vs ${match.teamBName}',
                      showBackButton: true,
                      onBack: () => context.go(AppRoutes.matches),
                      actions: [
                        RoundHeaderButton(
                          icon: FIcons.info,
                          onTap: () => showLegend(context, match),
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
                          ? () => showHalfTimePrompt(
                              context,
                              service,
                              match,
                              playersById,
                              repository,
                            )
                          : null,
                    ),
                    Expanded(
                      child: activePause == null
                          ? ListView(
                              padding: EdgeInsets.zero,
                              children: players
                                  .map(
                                    (player) => PlayerStatRow(
                                      player: player,
                                      enabledStatTypes: match.enabledStatTypes,
                                      oursOnOffense: oursOnOffense,
                                      hasDisc: player.id == discHolderId,
                                      noDiscHolder:
                                          oursOnOffense && discHolderId == null,
                                      onEvent: (type) async {
                                        final res = await service.record(
                                          match,
                                          type: type,
                                          player: player,
                                          playersById: playersById,
                                          repository: repository,
                                        );
                                        if (res.finished) {
                                          await triggerFinishMatch();
                                        } else if (res.scoredPoint &&
                                            context.mounted) {
                                          await triggerShowLineSelection(
                                            res.oursOnOffense,
                                          );
                                        }
                                      },
                                    ),
                                  )
                                  .toList(),
                            )
                          : PausePanel(
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
                            ),
                    ),
                    if (activePause == null)
                      BottomActions(
                        oursOnOffense: oursOnOffense,
                        showThrowaway: match.tracks(
                          MatchStatType.opponentError,
                        ),
                        timeoutLabel: 'TIMEOUT',
                        onGoal: () => confirmAndRecordGoal(
                          context,
                          service,
                          match,
                          MatchStatType.goal,
                          playersById,
                          repository,
                          triggerFinishMatch,
                          triggerShowLineSelection,
                        ),
                        onOpponentGoal: () => confirmAndRecordGoal(
                          context,
                          service,
                          match,
                          MatchStatType.opponentGoal,
                          playersById,
                          repository,
                          triggerFinishMatch,
                          triggerShowLineSelection,
                        ),
                        onOpponentError: () async {
                          final res = await service.record(
                            match,
                            type: MatchStatType.opponentError,
                            playersById: playersById,
                            repository: repository,
                          );
                          if (res.finished) {
                            await triggerFinishMatch();
                          }
                        },
                        onPull:
                            !oursOnOffense && match.tracks(MatchStatType.pull)
                            ? () async {
                                final draft = await showPullSheet(
                                  context,
                                  players,
                                );
                                if (draft == null) return;
                                await service.recordPull(
                                  match,
                                  player: draft.player,
                                  durationSeconds: draft.durationSeconds,
                                  inBounds: draft.inBounds,
                                  repository: repository,
                                );
                              }
                            : null,
                        onTimeout: match.hasTimeouts
                            ? () => service.record(
                                match,
                                type: MatchStatType.timeout,
                                playersById: playersById,
                                repository: repository,
                              )
                            : null,
                        onInjury: () => service.record(
                          match,
                          type: MatchStatType.injury,
                          playersById: playersById,
                          repository: repository,
                        ),
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
