import 'package:flutter/material.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/shared/sport_avatar_pill.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';

class RatingChangeRow extends StatelessWidget {
  const RatingChangeRow({
    super.key,
    required this.player,
    required this.initial,
    required this.finalRating,
    required this.delta,
  });

  final Player player;
  final double? initial;
  final double? finalRating;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _deltaColor(delta);
    final sign = delta > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassDecoration(
              radius: 24,
              child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            spacing: 12,
            children: [
              SportPlayerAvatar(
                initials: player.initials,
                imagePath: player.profileImagePath,
                size: 40,
              ),
              Expanded(
                child: Column(
                  spacing: 4,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${initial?.round() ?? '-'} -> ${finalRating?.round() ?? '-'}',
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
            ],
          ),
        ),
      ),
    );
  }

  Color _deltaColor(double delta) {
    if (delta > 0) return AppColors.violet;
    if (delta < 0) return AppColors.danger;
    return AppColors.sportMutedText;
  }
}
