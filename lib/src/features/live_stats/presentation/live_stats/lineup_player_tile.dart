import 'dart:io';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/players/domain/player.dart';

class LineupPlayerTile extends StatelessWidget {
  const LineupPlayerTile({
    super.key,
    required this.player,
    required this.selected,
    required this.pointsPlayed,
    required this.onTap,
  });

  final Player player;
  final bool selected;
  final int pointsPlayed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.24)
              : AppColors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.violetLight
                : AppColors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            spacing: 8,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: selected
                    ? AppColors.violet
                    : AppColors.white.withValues(alpha: 0.10),
                backgroundImage: player.profileImagePath == null
                    ? null
                    : FileImage(File(player.profileImagePath!)),
                child: player.profileImagePath == null
                    ? Text(
                        player.initials,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  spacing: 2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${player.linePreference?.label ?? 'Nessuna'} · ${player.role.label}',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.sportMutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.black.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Text(
                    '$pointsPlayed pt',
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.sportMutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? FIcons.circleCheck : FIcons.circle,
                color: selected
                    ? AppColors.violetLight
                    : AppColors.sportMutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
