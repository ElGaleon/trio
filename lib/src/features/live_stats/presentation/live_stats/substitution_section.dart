import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/domain/player_role.dart';

class SubstitutionSection extends StatelessWidget {
  const SubstitutionSection({
    super.key,
    required this.title,
    required this.players,
    required this.selectedId,
    required this.onSelect,
    this.highlightRole,
  });

  final String title;
  final List<Player> players;
  final String? selectedId;
  final PlayerRole? highlightRole;
  final ValueChanged<Player> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.sportMutedForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        if (players.isEmpty)
          Text(
            'Nessun giocatore disponibile',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.sportMutedForeground(context),
              fontWeight: FontWeight.w800,
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: players.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final player = players[index];
                final selected = selectedId == player.id;
                final highlighted =
                    highlightRole != null && player.role == highlightRole;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect(player),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.violet.withValues(alpha: 0.24)
                          : highlighted
                          ? AppColors.violet.withValues(alpha: 0.12)
                          : AppColors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? AppColors.violetLight
                            : highlighted
                            ? AppColors.violet
                            : AppColors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.sportForeground(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                Text(
                                  '${player.role.label} · ${player.linePreference?.label ?? 'Nessuna'}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.sportMutedForeground(
                                          context,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (highlighted)
                            Text(
                              'stesso ruolo',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: AppColors.violetLight,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          Icon(
                            selected ? FIcons.circleCheck : FIcons.circle,
                            color: selected
                                ? AppColors.violetLight
                                : AppColors.sportMutedText,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
