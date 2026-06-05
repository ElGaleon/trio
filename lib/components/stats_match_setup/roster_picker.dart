import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../model/player.dart';
import '../../theme/app_colors.dart';
import '../shared/sport_avatar_pill.dart';

class RosterPicker extends StatelessWidget {
  const RosterPicker({
    super.key,
    required this.players,
    required this.selectedIds,
    required this.minimum,
    required this.preferredLine,
    required this.onToggle,
  });

  final List<Player> players;
  final Set<String> selectedIds;
  final int minimum;
  final PlayerLinePreference preferredLine;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: sportGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          spacing: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Presenti · prima ${preferredLine.label}',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  '${selectedIds.length}/$minimum min',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            ...players.map((player) {
              final selected = selectedIds.contains(player.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onToggle(player.id),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.violet.withValues(alpha: 0.22)
                          : AppColors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? AppColors.violet
                            : AppColors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        spacing: 10,
                        children: [
                          SportPlayerAvatar(
                            initials: player.initials,
                            imagePath: player.profileImagePath,
                            size: 38,
                          ),
                          Expanded(
                            child: Text(
                              player.name,
                              style: textTheme.titleSmall?.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Icon(
                            selected ? FIcons.check : FIcons.plus,
                            color: selected
                                ? AppColors.violetLight
                                : AppColors.sportMutedText,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
