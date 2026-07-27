import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:skrim/src/shared/animated_score_stepper.dart';
import 'summary_row.dart';

class ScoreStep extends StatelessWidget {
  const ScoreStep({
    super.key,
    required this.scoreA,
    required this.scoreB,
    required this.onScoreAChanged,
    required this.onScoreBChanged,
    required this.teamSize,
    required this.teamALabel,
    required this.teamBLabel,
    required this.teamACount,
    required this.teamBCount,
  });

  final int scoreA;
  final int scoreB;
  final ValueChanged<int> onScoreAChanged;
  final ValueChanged<int> onScoreBChanged;
  final int teamSize;
  final String teamALabel;
  final String teamBLabel;
  final int teamACount;
  final int teamBCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12,
      children: [
        FCard(
          title: const Text('Riepilogo'),
          child: Column(
            children: [
              SummaryRow(label: 'Formato', value: '${teamSize}vs$teamSize'),
              SummaryRow(label: teamALabel, value: '$teamACount presenti'),
              SummaryRow(label: teamBLabel, value: '$teamBCount presenti'),
            ],
          ),
        ),
        Row(
          spacing: 12,
          children: [
            Expanded(
              child: AnimatedScoreStepper(
                label: teamALabel,
                value: scoreA,
                onChanged: onScoreAChanged,
              ),
            ),
            Expanded(
              child: AnimatedScoreStepper(
                label: teamBLabel,
                value: scoreB,
                onChanged: onScoreBChanged,
              ),
            ),
          ],
        ),
        if (scoreA == scoreB)
          Padding(
            padding: const EdgeInsets.only(top: 2), // Adjust spacing
            child: FBadge(variant: .secondary, child: const Text('Pareggio')),
          ),
      ],
    );
  }
}
