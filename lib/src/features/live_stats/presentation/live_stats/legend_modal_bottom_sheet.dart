import 'package:flutter/material.dart';

import 'package:trio/src/shared/decorated_panel.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'legend_row.dart';

class LegendModalBottomSheet extends StatelessWidget {
  final ScrimmageMatch match;
  final Set<MatchStatType> enabled;

  const LegendModalBottomSheet({
    super.key,
    required this.match,
    required this.enabled,
  });

  static void show(BuildContext context, ScrimmageMatch match) {
    final enabled = match.enabledStatTypes.toSet();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) =>
          LegendModalBottomSheet(match: match, enabled: enabled),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: DecoratedPanel(
          child: Padding(
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
}
