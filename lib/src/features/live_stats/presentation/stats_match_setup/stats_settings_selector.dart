import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';
import 'stat_toggle_chip.dart';

class StatsSettingsSelector extends ConsumerWidget {
  const StatsSettingsSelector({
    super.key,
    required this.enabledStatTypes,
    required this.enabledCustomStatIds,
    required this.onToggle,
    required this.onToggleCustomStat,
  });

  final Set<MatchStatType> enabledStatTypes;
  final Set<String> enabledCustomStatIds;
  final ValueChanged<MatchStatType> onToggle;
  final ValueChanged<String> onToggleCustomStat;

  static const _items = [
    (MatchStatType.pass, 'P', 'Passaggi'),
    (MatchStatType.huck, 'H', 'Huck'),
    (MatchStatType.catchDisc, 'C', 'Catch / possesso'),
    (MatchStatType.throwError, 'TE', 'Throw error'),
    (MatchStatType.catchError, 'RE', 'Receive error'),
    (MatchStatType.stallOut, 'S', 'Stall out'),
    (MatchStatType.block, 'B', 'Block'),
    (MatchStatType.pull, 'PU', 'Pull'),
    (MatchStatType.openError, 'A', 'Errore aperto'),
    (MatchStatType.deepError, 'BU', 'Errore buco'),
    (MatchStatType.resetError, 'R', 'Errore reset'),
    (MatchStatType.opponentError, 'TO', 'Throwaway avversario'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final customStats = settings.customStats;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sportForeground(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.sportForeground(context).withValues(alpha: 0.12),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              spacing: 4,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistiche da tracciare',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Questo set viene salvato nel match e non modifica le partite vecchie.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedForeground(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in _items)
                  StatToggleChip(
                    code: item.$2,
                    label: item.$3,
                    selected: enabledStatTypes.contains(item.$1),
                    onTap: () => onToggle(item.$1),
                  ),
              ],
            ),
            if (customStats.isNotEmpty) ...[
              Divider(
                color: AppColors.sportForeground(
                  context,
                ).withValues(alpha: 0.12),
                height: 24,
              ),
              Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistiche personalizzate',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Abilita le statistiche che hai creato nelle impostazioni.',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final stat in customStats)
                    StatToggleChip(
                      code: stat.abbreviation,
                      label: stat.label,
                      selected: enabledCustomStatIds.contains(stat.id),
                      onTap: () => onToggleCustomStat(stat.id),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
