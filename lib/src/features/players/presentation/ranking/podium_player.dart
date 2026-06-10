import 'package:flutter/material.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/shared/sport_avatar_pill.dart';
import 'rank_badge.dart';
import 'rating_pill.dart';

class PodiumPlayer extends StatelessWidget {
  const PodiumPlayer({
    super.key,
    required this.player,
    required this.rank,
    required this.featured,
    required this.allAtInitialRating,
    required this.onTap,
  });

  final Player player;
  final int? rank;
  final bool featured;
  final bool allAtInitialRating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarSize = featured ? 92.0 : 70.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.only(top: featured ? 0 : 28),
        child: Column(
          spacing: 8,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SportPlayerAvatar(
                  initials: player.initials,
                  imagePath: player.profileImagePath,
                  size: avatarSize,
                  featured: featured,
                ),
                Positioned(
                  top: -4,
                  left: -2,
                  child: RankBadge(
                    rank: rank,
                    muted: allAtInitialRating,
                    compact: !featured,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2), // Adjust spacing to get 10
              child: Text(
                _shortName(player.name),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            RatingPill(
              rating: player.rating.round(),
              emphasized: featured,
            ),
          ],
        ),
      ),
    );
  }

  String _shortName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.isEmpty) return value;
    if (parts.length == 1) return parts.first;
    return '${parts.first} ${parts.last.characters.first}.';
  }
}
