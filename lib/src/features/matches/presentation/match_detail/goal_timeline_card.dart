import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'goal_timeline_row.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';

class GoalTimelineCard extends StatelessWidget {
  const GoalTimelineCard({super.key, required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context) {
    final goals = match.statEvents
        .where(
          (event) =>
              event.type == MatchStatType.goal ||
              event.type == MatchStatType.opponentGoal,
        )
        .toList();
    if (goals.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(FIcons.flag, color: AppColors.violet, size: 18),
                Text(
                  'Timeline mete',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            for (final (index, goal) in goals.indexed)
              GoalTimelineRow(
                goal: goal,
                match: match,
                isLast: index == goals.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}
