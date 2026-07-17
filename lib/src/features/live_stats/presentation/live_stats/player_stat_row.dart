import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/application/player_providers.dart';
import 'package:trio/src/features/settings/domain/custom_stat.dart';
import 'stat_button.dart';

class PlayerStatRow extends ConsumerWidget {
  const PlayerStatRow({
    super.key,
    required this.player,
    required this.enabledStatTypes,
    required this.enabledCustomStatIds,
    required this.oursOnOffense,
    required this.hasDisc,
    required this.noDiscHolder,
    required this.onEvent,
  });

  final Player player;
  final List<MatchStatType> enabledStatTypes;
  final List<String> enabledCustomStatIds;
  final bool oursOnOffense;
  final bool hasDisc;
  final bool noDiscHolder;
  final void Function(MatchStatType type, String? customStatId) onEvent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final customStats = settings.customStats;
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasDisc
            ? AppColors.violet.withValues(alpha: 0.10)
            : AppColors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Row(
          spacing: 8,
          children: [
            SizedBox(
              width: 112,
              child: Row(
                spacing: 8,
                children: [
                  Text(
                    _numberLabel(player),
                    style: textTheme.titleLarge?.copyWith(
                      color: AppColors.sportMutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          hasDisc ? 'disco' : player.role.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: hasDisc
                                ? AppColors.violetLight
                                : AppColors.sportMutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final actions = _visibleActions(customStats);
                  final useFullLabels = _fullLabelsFit(
                    actions,
                    constraints.maxWidth,
                  );
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    child: Row(
                      spacing: 6,
                      children: _buttons(actions, useFullLabels),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<
    ({
      String short,
      String full,
      MatchStatType type,
      String? customStatId,
      bool destructive,
    })
  >
  _visibleActions(List<CustomStat> customStats) {
    final enabled = enabledStatTypes.toSet();
    final builtInActions = oursOnOffense
        ? hasDisc
              ? const [
                  (
                    short: 'TE',
                    full: 'Throw error',
                    type: MatchStatType.throwError,
                    destructive: true,
                  ),
                  (
                    short: 'Stall',
                    full: 'Stall out',
                    type: MatchStatType.stallOut,
                    destructive: true,
                  ),
                ]
              : noDiscHolder
              ? const [
                  (
                    short: 'Catch',
                    full: 'Catch',
                    type: MatchStatType.catchDisc,
                    destructive: false,
                  ),
                  (
                    short: 'RE',
                    full: 'Receive error',
                    type: MatchStatType.catchError,
                    destructive: true,
                  ),
                ]
              : const [
                  (
                    short: 'Pass',
                    full: 'Passaggio',
                    type: MatchStatType.pass,
                    destructive: false,
                  ),
                  (
                    short: 'Huck',
                    full: 'Huck',
                    type: MatchStatType.huck,
                    destructive: false,
                  ),
                  (
                    short: 'RE',
                    full: 'Receive error',
                    type: MatchStatType.catchError,
                    destructive: true,
                  ),
                ]
        : const [
            (
              short: 'Stall',
              full: 'Stall out',
              type: MatchStatType.stallOut,
              destructive: false,
            ),
            (
              short: 'Catch',
              full: 'Catch',
              type: MatchStatType.catchDisc,
              destructive: false,
            ),
            (
              short: 'Block',
              full: 'Block',
              type: MatchStatType.block,
              destructive: false,
            ),
            (
              short: 'A',
              full: 'Aperto',
              type: MatchStatType.openError,
              destructive: true,
            ),
            (
              short: 'Buco',
              full: 'Buco',
              type: MatchStatType.deepError,
              destructive: true,
            ),
            (
              short: 'Reset',
              full: 'Reset',
              type: MatchStatType.resetError,
              destructive: true,
            ),
          ];

    final List<
      ({
        String short,
        String full,
        MatchStatType type,
        String? customStatId,
        bool destructive,
      })
    >
    visible = [];

    for (final action in builtInActions) {
      if (enabled.contains(action.type)) {
        visible.add((
          short: action.short,
          full: action.full,
          type: action.type,
          customStatId: null,
          destructive: action.destructive,
        ));
      }
    }

    for (final stat in customStats) {
      if (enabledCustomStatIds.contains(stat.id)) {
        if (oursOnOffense) {
          if (hasDisc && stat.isError) {
            visible.add((
              short: stat.abbreviation,
              full: stat.label,
              type: MatchStatType.custom,
              customStatId: stat.id,
              destructive: true,
            ));
          } else if (!hasDisc && !stat.isError) {
            visible.add((
              short: stat.abbreviation,
              full: stat.label,
              type: MatchStatType.custom,
              customStatId: stat.id,
              destructive: false,
            ));
          }
        } else {
          if (!stat.isError) {
            visible.add((
              short: stat.abbreviation,
              full: stat.label,
              type: MatchStatType.custom,
              customStatId: stat.id,
              destructive: false,
            ));
          }
        }
      }
    }

    return visible;
  }

  bool _fullLabelsFit(
    List<
      ({
        String short,
        String full,
        MatchStatType type,
        String? customStatId,
        bool destructive,
      })
    >
    actions,
    double maxWidth,
  ) {
    final estimated = actions.fold<double>(
      0,
      (total, action) => total + 24 + (action.full.length * 7.4),
    );
    final spacing = actions.isEmpty ? 0 : (actions.length - 1) * 6;
    return estimated + spacing <= maxWidth + 24;
  }

  List<Widget> _buttons(
    List<
      ({
        String short,
        String full,
        MatchStatType type,
        String? customStatId,
        bool destructive,
      })
    >
    visibleActions,
    bool useFullLabels,
  ) {
    if (visibleActions.isEmpty) {
      return [
        const Text(
          'Nessuna stat',
          style: TextStyle(
            color: AppColors.sportMutedText,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ];
    }
    return [
      for (final action in visibleActions)
        StatButton(
          label: useFullLabels ? action.full : action.short,
          destructive: action.destructive,
          onTap: () => onEvent(action.type, action.customStatId),
        ),
    ];
  }

  String _numberLabel(Player player) {
    return player.jerseyNumber?.toString() ??
        ((player.id.hashCode.abs() % 98) + 1).toString();
  }
}
