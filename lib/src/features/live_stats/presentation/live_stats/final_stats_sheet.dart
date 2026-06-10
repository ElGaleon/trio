import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/shared/decorated_panel.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/live_stats/domain/live_match_stats_summary.dart';
import 'general_action_button.dart';
import 'stats_summary_view.dart';

class FinalStatsSheet {
  const FinalStatsSheet._();

  static Future<void> show(
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
          child: DecoratedPanel(
            radius: 28,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.82,
              ),
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
      ),
    );
  }
}
