import 'package:flutter/material.dart';
import 'package:skrim/src/extensions/double_extension.dart';
import 'package:skrim/src/features/live_stats/domain/live_match_stats_summary.dart';
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
            MetricPill(label: 'Mete', value: '${summary.goals}'),
            MetricPill(label: 'Turnover', value: '${summary.turnovers}'),
            MetricPill(label: 'Break fatti', value: '${summary.breaks}'),
            MetricPill(
              label: 'Break subiti',
              value: '${summary.breaksConceded}',
            ),
            MetricPill(
              label: 'Turnover generati',
              value: '${summary.generatedTurnovers}',
            ),
            MetricPill(
              label: 'Precisione passaggi',
              value: summary.passAccuracy.percent,
            ),
            MetricPill(
              label: 'Conversione attacco',
              value: summary.oLineEffectiveness.percent,
            ),
            MetricPill(
              label: 'Attacchi puliti',
              value: summary.cleanOffenseRatio.percent,
            ),
            MetricPill(
              label: 'Turnover/difese',
              value: summary.dLineTurnoverRatio.percent,
            ),
            MetricPill(
              label: 'Conversione dopo turnover',
              value: summary.dLineConversionRatio.percent,
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatsSection(
          title: 'Leader giocatori',
          children: [
            MetricPill(label: 'Top scorer', value: summary.topScorer),
            MetricPill(label: 'Assist', value: summary.mostAssist),
            MetricPill(
              label: 'Assist secondari',
              value: summary.mostSecondaryAssist,
            ),
            MetricPill(label: 'Tocchi', value: summary.mostTouches),
            MetricPill(label: 'Difesa', value: summary.bestDefender),
            MetricPill(label: 'Piu in campo', value: summary.mostPlayed),
            MetricPill(label: 'Connessione', value: summary.bestConnection),
            MetricPill(
              label: 'Coppia assist/meta',
              value: summary.bestAssistGoalPair,
            ),
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
