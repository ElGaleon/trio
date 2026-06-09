import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/common_widgets/sport_avatar_pill.dart';
import 'rank_badge.dart';
import 'rating_pill.dart';
import 'package:trio/src/common_widgets/sport_glass_decoration_helper.dart';

class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.player,
    required this.rank,
    required this.allAtInitialRating,
    required this.onTap,
  });

  final Player player;
  final int? rank;
  final bool allAtInitialRating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: sportGlassDecoration(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              spacing: 12,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '${rank ?? '-'}',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SportPlayerAvatar(
                  initials: player.initials,
                  imagePath: player.profileImagePath,
                  size: 42,
                ),
                Expanded(
                  child: Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!allAtInitialRating && (rank ?? 99) <= 3)
                  Icon(FIcons.trophy, size: 16, color: rankColor(rank)),
                RatingPill(rating: player.rating.round()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
