import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/player.dart';
import 'card_actions_menu.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
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
        child: FCard.raw(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Hero(
                  tag: 'player-${player.id}',
                  child: FAvatar.raw(size: 48.0, child: Text(player.initials)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: textTheme.titleMedium?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${player.role.label} · ${player.linePreference.label}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
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
