import 'package:flutter/material.dart';

import '../../model/scrimmage_match.dart';
import '../../theme/app_colors.dart';
import 'stat_toggle_chip.dart';

class StatsSettingsSelector extends StatelessWidget {
  const StatsSettingsSelector({
    super.key,
    required this.enabledStatTypes,
    required this.onToggle,
  });

  final Set<MatchStatType> enabledStatTypes;
  final ValueChanged<MatchStatType> onToggle;

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
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
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
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Questo set viene salvato nel match e non modifica le partite vecchie.',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
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
          ],
        ),
      ),
    );
  }
}
