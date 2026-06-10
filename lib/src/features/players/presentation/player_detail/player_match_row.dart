import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';

class PlayerMatchRow extends StatelessWidget {
  const PlayerMatchRow({
    super.key,
    required this.player,
    required this.match,
    required this.playersById,
  });

  final Player player;
  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isTeamA = match.teamAIds.contains(player.id);
    final resultLabel = match.isDraw
        ? 'Pareggio'
        : (isTeamA == match.teamAWon ? 'Vittoria' : 'Sconfitta');
    final delta = match.ratingDelta(player.id);
    final color = _deltaColor(delta);
    final sign = delta > 0 ? '+' : '';
    final teammates = (isTeamA ? match.teamAIds : match.teamBIds)
        .where((id) => id != player.id)
        .map((id) => playersById[id]?.name)
        .whereType<String>()
        .join(', ');
    final teamName = isTeamA ? match.teamAName : match.teamBName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassDecoration(
              radius: 24,
              child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            spacing: 12,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.50)),
                  ),
                  child: Center(
                    child: Icon(_resultIcon(match, isTeamA, delta), color: color),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$teamName · ${match.scoreA} - ${match.scoreB}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$resultLabel · ${teammates.isEmpty ? 'Nessun compagno' : teammates}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 2), // Adjust spacing: 10 total (12 gap - 2 padding = 10)
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: color.withValues(alpha: 0.45)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      '$sign${delta.round()}',
                      style: textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _resultIcon(ScrimmageMatch match, bool isTeamA, double delta) {
    if (match.isDraw || delta == 0) return FIcons.minus;
    return isTeamA == match.teamAWon ? FIcons.trendingUp : FIcons.trendingDown;
  }

  Color _deltaColor(double delta) {
    if (delta > 0) return AppColors.violet;
    if (delta < 0) return AppColors.danger;
    return AppColors.sportMutedText;
  }
}
