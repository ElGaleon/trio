import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/players/presentation/player_detail/info_pill.dart';
import 'package:trio/src/common_widgets/sport_avatar_pill.dart';
import 'package:trio/src/common_widgets/sport_glass_decoration_helper.dart';

class TeamBlock extends StatelessWidget {
  const TeamBlock({
    super.key,
    required this.title,
    required this.players,
    required this.won,
  });

  final String title;
  final List<Player> players;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: sportGlassDecoration(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(FIcons.users, size: 18, color: AppColors.violet),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (won) const InfoPill(label: 'Win', emphasized: true),
              ],
            ),
            if (players.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Squadra esterna',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else
              ...players.map(
                (player) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    spacing: 10,
                    children: [
                      SportPlayerAvatar(
                        initials: player.initials,
                        imagePath: player.profileImagePath,
                        size: 36,
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
                              [
                                player.role.label,
                                player.linePreference?.label ?? 'Nessuna',
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
                      InfoPill(label: player.rating.round().toString()),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
