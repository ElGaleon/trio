import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trio/app_constants.dart';

import '../models/player.dart';
import 'card_actions_menu.dart';

class PlayerRankingCard extends StatelessWidget {
  const PlayerRankingCard({
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
    final trophyColor = _trophyColor(rank);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTap: onTap,
        child: Hero(
          tag: 'player-${player.id}',
          child: FCard.raw(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                spacing: 8,
                children: [
                  FAvatar.raw(
                    size: 48,
                    child:
                        trophyColor == null ||
                            AppConstants.initialRating == player.rating
                        ? Text(
                            '#${rank ?? ''}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          )
                        : Icon(FIcons.trophy, color: trophyColor, size: 30),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          player.name,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${player.matchesPlayed}G · ${player.wins}V · ${player.losses}S · ${(player.winRate * 100).round()}%',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF71717A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: player.rating),
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    builder: (context, rating, _) {
                      return Text(
                        rating.round().toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      );
                    },
                  ),
                  if (onEdit != null && onDelete != null)
                    CardActionsMenu(onEdit: onEdit!, onDelete: onDelete!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Color? _trophyColor(int? rank) {
  return switch (rank) {
    1 => const Color(0xFFEAB308),
    2 => const Color(0xFF94A3B8),
    3 => const Color(0xFFB45309),
    _ => null,
  };
}
