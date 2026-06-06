import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../model/player.dart';
import '../../theme/app_colors.dart';
import '../shared/sport_avatar_pill.dart';
import 'info_pill.dart';

class PlayerHero extends StatelessWidget {
  const PlayerHero({super.key, required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Hero(
      tag: 'player-${player.id}',
      child: DecoratedBox(
        decoration: sportGlassDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.white.withValues(alpha: 0.16),
              AppColors.white.withValues(alpha: 0.045),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SportPlayerAvatar(
                initials: player.initials,
                imagePath: player.profileImagePath,
                size: 76,
                featured: true,
              ),
              Expanded(
                child: Column(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        InfoPill(
                          icon: FIcons.sparkles,
                          label: '${player.rating.round()} ELO',
                          emphasized: true,
                        ),
                        InfoPill(label: player.role.label),
                        InfoPill(label: player.linePreference.label),
                        if (player.jerseyNumber != null)
                          InfoPill(label: '#${player.jerseyNumber}'),
                        if (player.isExternal) const InfoPill(label: 'Esterno'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
