import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../model/scrimmage_match.dart';
import '../../theme/app_colors.dart';
import '../../model/live_stats_models.dart';
import '../shared/sport_screen_shell.dart';
import 'action_buttons.dart';

class ActivePause {
  const ActivePause({
    required this.type,
    required this.endType,
    required this.title,
    required this.remaining,
    required this.nextOnOffense,
  });

  final MatchStatType type;
  final MatchStatType endType;
  final String title;
  final Duration remaining;
  final bool nextOnOffense;
}

class MetricPill extends StatelessWidget {
  const MetricPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: sportMutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsSection extends StatelessWidget {
  const StatsSection({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: children),
          ],
        ),
      ),
    );
  }
}

class StatsSummaryView extends StatelessWidget {
  const StatsSummaryView({super.key, required this.summary});

  final LiveMatchStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        StatsSection(
          title: 'Team',
          children: [
            MetricPill(label: 'Goals', value: '${summary.goals}'),
            MetricPill(label: 'Turnover', value: '${summary.turnovers}'),
            MetricPill(label: 'Break', value: '${summary.breaks}'),
            MetricPill(
              label: 'Pass accuracy',
              value: summary.percent(summary.passAccuracy),
            ),
            MetricPill(
              label: 'O-line effectiveness',
              value: summary.percent(summary.oLineEffectiveness),
            ),
            MetricPill(
              label: 'O-line efficiency',
              value: summary.percent(summary.oLineEfficiency),
            ),
            MetricPill(
              label: 'D-line turnover',
              value: summary.percent(summary.dLineTurnoverRatio),
            ),
            MetricPill(
              label: 'D-line conversion',
              value: summary.percent(summary.dLineConversionRatio),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatsSection(
          title: 'Player leaders',
          children: [
            MetricPill(label: 'Top scorer', value: summary.topScorer),
            MetricPill(label: 'Most assist', value: summary.mostAssist),
            MetricPill(label: 'Most touches', value: summary.mostTouches),
            MetricPill(label: 'Best defender', value: summary.bestDefender),
            MetricPill(label: 'Most played', value: summary.mostPlayed),
          ],
        ),
        const SizedBox(height: 12),
        StatsSection(
          title: 'Points played',
          children: [
            for (final item in summary.pointsPlayed)
              MetricPill(label: item.name, value: '${item.value} pt'),
          ],
        ),
      ],
    );
  }
}

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
                    color: sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4), // extra spacing to separate buttons
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
