import 'package:flutter/material.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'podium_player.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';

class LeaderboardShowcase extends StatelessWidget {
  const LeaderboardShowcase({
    super.key,
    required this.players,
    required this.rankByPlayerId,
    required this.allAtInitialRating,
    required this.onPlayerTap,
  });

  final List<Player> players;
  final Map<String, int> rankByPlayerId;
  final bool allAtInitialRating;
  final ValueChanged<Player> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final ordered = switch (players.length) {
      >= 3 => [players[1], players[0], players[2]],
      _ => players,
    };
    return GlassDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.white.withValues(alpha: 0.16),
          AppColors.white.withValues(alpha: 0.045),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: -24,
            child: Text(
              '#1',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.white.withValues(alpha: 0.055),
                fontSize: 118,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final player in ordered)
                  Expanded(
                    child: PodiumPlayer(
                      player: player,
                      rank: rankByPlayerId[player.id],
                      featured: players.isNotEmpty && player.id == players.first.id,
                      allAtInitialRating: allAtInitialRating,
                      onTap: () => onPlayerTap(player),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
