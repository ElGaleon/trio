import 'package:flutter/material.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';

class LineAverageSummary extends StatelessWidget {
  const LineAverageSummary({super.key, required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final offenseAverage = _averageRating(
      players.where(
        (player) => player.linePreference == PlayerLinePreference.offense,
      ),
    );
    final defenseAverage = _averageRating(
      players.where(
        (player) => player.linePreference == PlayerLinePreference.defense,
      ),
    );

    return Row(
      spacing: 10,
      children: [
        AverageCard(label: 'Media attacco', value: offenseAverage),
        AverageCard(label: 'Media difesa', value: defenseAverage),
      ],
    );
  }

  double? _averageRating(Iterable<Player> players) {
    if (players.isEmpty) return null;
    final total = players
        .map((player) => player.rating)
        .reduce((a, b) => a + b);
    return total / players.length;
  }
}

class AverageCard extends StatelessWidget {
  const AverageCard({super.key, required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: GlassDecoration(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.sportMutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                value == null ? '-' : value!.round().toString(),
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
