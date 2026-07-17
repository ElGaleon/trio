import 'package:flutter/material.dart';

import 'package:trio/src/shared/match_card.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';

class CompactMatchTitle extends StatelessWidget {
  const CompactMatchTitle({super.key, required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 7,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Transform.scale(
                scale: 0.54,
                child: TeamLogo(
                  name: match.teamAName,
                  highlighted: !match.isDraw && match.teamAWon,
                ),
              ),
              Flexible(
                child: Text(
                  match.teamAName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          '${match.scoreA} - ${match.scoreB}',
          style: textTheme.titleSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Flexible(
                child: Text(
                  match.teamBName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.54,
                child: TeamLogo(
                  name: match.teamBName,
                  highlighted: !match.isDraw && !match.teamAWon,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
