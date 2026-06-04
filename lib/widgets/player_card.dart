import 'package:flutter/material.dart';

import '../models/player.dart';
import '../theme/app_colors.dart';
import 'card_actions_menu.dart';
import 'sport_style.dart';

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
        child: Container(
          decoration: sportGlassDecoration(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Hero(
                  tag: 'player-${player.id}',
                  child: SportPlayerAvatar(
                    initials: player.initials,
                    imagePath: player.profileImagePath,
                    size: 48,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
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
                      const SizedBox(height: 4),
                      Text(
                        [
                          player.role.label,
                          player.linePreference.label,
                          if (player.isExternal) 'Esterno',
                        ].join(' · '),
                        style: textTheme.bodySmall?.copyWith(
                          color: sportMutedText,
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
