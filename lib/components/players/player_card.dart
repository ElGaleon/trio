import 'package:flutter/material.dart';

import '../../model/player.dart';
import '../../theme/app_colors.dart';
import '../shared/card_actions_menu.dart';
import '../shared/sport_avatar_pill.dart';

class PlayerCard extends StatelessWidget {
  const PlayerCard({
    super.key,
    required this.player,
    this.rank,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final Player player;
  final int? rank;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: sportGlassDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              spacing: 14,
              children: [
                Hero(
                  tag: 'player-${player.id}',
                  child: SportPlayerAvatar(
                    initials: player.initials,
                    imagePath: player.profileImagePath,
                    size: 48,
                  ),
                ),
                Expanded(
                  child: Column(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        [
                          player.role.label,
                          player.linePreference.label,
                          if (player.isExternal) 'Esterno',
                        ].join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.sportMutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onEdit != null && onDelete != null)
                  CardActionsMenu(onEdit: onEdit!, onDelete: onDelete!),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
