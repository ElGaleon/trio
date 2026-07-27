import 'package:flutter/material.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';

class ScoreHero extends StatelessWidget {
  const ScoreHero({super.key, required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GlassDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.white.withValues(alpha: 0.12),
          AppColors.white.withValues(alpha: 0.03),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          spacing: 14,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  match.matchType.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.violetLight,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${match.teamSize}vs${match.teamSize} · ${match.division}',
                  style: textTheme.labelSmall?.copyWith(
                    color: sportMutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Row(
              spacing: 14,
              children: [
                Expanded(
                  child: Text(
                    match.teamAName,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${match.scoreA}',
                  style: textTheme.headlineMedium?.copyWith(
                    color: !match.isDraw && match.teamAWon
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    '·',
                    style: textTheme.bodySmall?.copyWith(
                      color: sportMutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${match.scoreB}',
                  style: textTheme.headlineMedium?.copyWith(
                    color: !match.isDraw && !match.teamAWon
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Expanded(
                  child: Text(
                    match.teamBName,
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
