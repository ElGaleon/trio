import 'package:flutter/material.dart';

import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'stats_settings_selector.dart';

class StatsSelectionStep extends StatelessWidget {
  const StatsSelectionStep({
    super.key,
    required this.enabledStatTypes,
    required this.enabledCustomStatIds,
    required this.onToggleStat,
    required this.onToggleCustomStat,
  });

  final Set<MatchStatType> enabledStatTypes;
  final Set<String> enabledCustomStatIds;
  final ValueChanged<MatchStatType> onToggleStat;
  final ValueChanged<String> onToggleCustomStat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassDecoration(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiche live',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Scegli solo le azioni che vuoi davvero segnare durante questa partita. La scelta resta salvata nel match.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.sportMutedForeground(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            StatsSettingsSelector(
              enabledStatTypes: enabledStatTypes,
              enabledCustomStatIds: enabledCustomStatIds,
              onToggle: onToggleStat,
              onToggleCustomStat: onToggleCustomStat,
            ),
          ],
        ),
      ),
    );
  }
}
