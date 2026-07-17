import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';

class PreMatchBlock extends StatelessWidget {
  const PreMatchBlock({
    super.key,
    required this.ratingA,
    required this.ratingB,
    required this.delta,
    required this.probabilityA,
    required this.probabilityB,
    required this.teamAName,
    required this.teamBName,
  });

  final double ratingA;
  final double ratingB;
  final double delta;
  final double probabilityA;
  final double probabilityB;
  final String teamAName;
  final String teamBName;

  @override
  Widget build(BuildContext context) {
    final sign = delta >= 0 ? '+' : '';
    return Column(
      spacing: 10,
      children: [
        Row(
          spacing: 10,
          children: [
            MetricCard(label: teamAName, value: ratingA.round().toString()),
            MetricCard(label: teamBName, value: ratingB.round().toString()),
          ],
        ),
        MetricRow(label: 'Delta pre-match', value: '$sign${delta.round()}'),
        MetricRow(
          label: 'Probabilita $teamAName',
          value: '${(probabilityA * 100).round()}%',
        ),
        MetricRow(
          label: 'Probabilita $teamBName',
          value: '${(probabilityB * 100).round()}%',
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: GlassDecoration(
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            spacing: 6,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(FIcons.shield, size: 18, color: AppColors.violet),
              Padding(
                padding: const EdgeInsets.only(top: 4), // Adjust to get 10
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                value,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassDecoration(
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
