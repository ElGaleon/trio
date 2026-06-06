import 'package:flutter/material.dart';

import '../../model/scrimmage_match.dart';
import '../../theme/app_colors.dart';
import '../shared/sport_avatar_pill.dart';
import 'stats_settings_selector.dart';

class StatsSelectionStep extends StatelessWidget {
  const StatsSelectionStep({
    super.key,
    required this.enabledStatTypes,
    required this.onToggleStat,
  });

  final Set<MatchStatType> enabledStatTypes;
  final ValueChanged<MatchStatType> onToggleStat;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: sportGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiche live',
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Scegli solo le azioni che vuoi davvero segnare durante questa partita. La scelta resta salvata nel match.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.sportMutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            StatsSettingsSelector(
              enabledStatTypes: enabledStatTypes,
              onToggle: onToggleStat,
            ),
          ],
        ),
      ),
    );
  }
}
