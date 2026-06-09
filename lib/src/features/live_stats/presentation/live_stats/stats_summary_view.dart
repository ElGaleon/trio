import 'package:flutter/material.dart';
import 'package:trio/src/extensions/double_extension.dart';
import 'package:trio/src/features/live_stats/domain/live_match_stats_summary.dart';
import 'metric_pill.dart';
import 'stats_section.dart';

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
              value: summary.passAccuracy.percent,
            ),
            MetricPill(
              label: 'O-line effectiveness',
              value: summary.oLineEffectiveness.percent,
            ),
            MetricPill(
              label: 'O-line efficiency',
              value: summary.oLineEfficiency.percent,
            ),
            MetricPill(
              label: 'D-line turnover',
              value: summary.dLineTurnoverRatio.percent,
            ),
            MetricPill(
              label: 'D-line conversion',
              value: summary.dLineConversionRatio.percent,
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
