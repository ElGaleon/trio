import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/domain/match_stat_type.dart';
import 'package:trio/src/features/matches/domain/match_stat_event.dart';

class GoalTimelineRow extends StatelessWidget {
  const GoalTimelineRow({
    super.key,
    required this.goal,
    required this.match,
    required this.isLast,
  });

  final MatchStatEvent goal;
  final ScrimmageMatch match;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOurGoal = goal.type == MatchStatType.goal;
    final teamName = isOurGoal ? match.teamAName : match.teamBName;
    final minute = goal.createdAt.difference(match.createdAt).inMinutes;
    final description = goal.description?.trim().isNotEmpty == true
        ? goal.description!
        : '${goal.type.label} $teamName';
    final accent = isOurGoal ? AppColors.violet : AppColors.white;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isOurGoal ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.34)),
                ),
                child: Icon(
                  isOurGoal ? FIcons.flag : FIcons.circleDot,
                  color: accent,
                  size: 17,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.sportForeground(
                      context,
                    ).withValues(alpha: 0.10),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                spacing: 3,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.sportForeground(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${goal.scoreA} - ${goal.scoreB}',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.sportForeground(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${minute <= 0 ? 1 : minute}’ · $teamName',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
