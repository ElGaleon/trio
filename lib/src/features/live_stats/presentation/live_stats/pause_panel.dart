import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/live_stats/domain/live_match_stats_summary.dart';
import 'active_pause.dart';
import 'general_action_button.dart';
import 'stats_summary_view.dart';

class PausePanel extends StatelessWidget {
  const PausePanel({
    super.key,
    required this.pause,
    required this.summary,
    required this.onSelectLine,
    required this.onEndPause,
  });

  final ActivePause pause;
  final LiveMatchStatsSummary summary;
  final VoidCallback onSelectLine;
  final VoidCallback onEndPause;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.sportHeaderDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.40),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pause.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      _formatPause(pause.remaining),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.violetLight,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Durante la pausa puoi scegliere la prossima linea e leggere le statistiche intermedie.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: GeneralActionButton(
                          label: 'LINEA',
                          icon: FIcons.users,
                          accent: AppColors.violet,
                          compact: true,
                          onTap: onSelectLine,
                        ),
                      ),
                      Expanded(
                        child: GeneralActionButton(
                          label: 'FINISCI',
                          icon: FIcons.timerOff,
                          accent: AppColors.appDarkElevated,
                          compact: true,
                          onTap: onEndPause,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        StatsSummaryView(summary: summary),
      ],
    );
  }

  String _formatPause(Duration duration) {
    final total = duration.inSeconds.clamp(0, 24 * 60 * 60);
    final minutes = (total ~/ 60).toString().padLeft(2, '0');
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
