import 'dart:async';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/shared/decorated_panel.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'general_action_button.dart';
import 'pull_draft.dart';
import 'pull_player_chip.dart';
import 'pull_timer_display.dart';
import 'square_action_button.dart';

class PullStopwatchSheet extends StatefulWidget {
  const PullStopwatchSheet({super.key, required this.players});

  final List<Player> players;

  @override
  State<PullStopwatchSheet> createState() => _PullStopwatchSheetState();
}

class _PullStopwatchSheetState extends State<PullStopwatchSheet> {
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
        child: DecoratedPanel(
          radius: 28,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.72,
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 14,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cronometro pull',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  _hasStarted
                      ? 'Ferma il cronometro scegliendo se il pull e rimasto dentro o e uscito.'
                      : 'Seleziona il tiratore e avvia il cronometro quando parte il pull.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedForeground(context),
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
                          PullPlayerChip(
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
                PullTimerDisplay(
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
      ),
    );
  }
}
