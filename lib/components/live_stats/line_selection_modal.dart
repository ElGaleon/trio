import 'dart:io';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../../model/player.dart';
import '../../model/scrimmage_match.dart';
import '../../theme/app_colors.dart';
import '../shared/sport_button.dart';
import '../shared/sport_screen_shell.dart';

BoxDecoration solidPanelDecoration({double radius = 22}) {
  return BoxDecoration(
    color: AppColors.sportHeaderDark,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.white.withValues(alpha: 0.14)),
    boxShadow: [
      BoxShadow(
        color: AppColors.black.withValues(alpha: 0.40),
        blurRadius: 28,
        offset: const Offset(0, 16),
      ),
    ],
  );
}

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
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.violetLight
                : AppColors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            spacing: 10,
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
                      '${player.linePreference.label} · ${player.role.label}',
                      style: textTheme.bodySmall?.copyWith(
                        color: sportMutedText,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  child: Text(
                    '$pointsPlayed pt',
                    style: textTheme.labelMedium?.copyWith(
                      color: sportMutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected ? FIcons.circleCheck : FIcons.circle,
                color: selected ? AppColors.violetLight : sportMutedText,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<Set<String>?> showLineSelectionSheet(
  BuildContext context, {
  required ScrimmageMatch match,
  required List<Player> allPlayers,
  required int Function(String playerId) getPointsPlayed,
  required bool nextOnOffense,
}) {
  final preferred = nextOnOffense
      ? PlayerLinePreference.offense
      : PlayerLinePreference.defense;
  final selected = match.teamAIds.toSet();
  final sorted = [...allPlayers]
    ..sort((a, b) {
      final byLine = (a.linePreference == preferred ? 0 : 1).compareTo(
        b.linePreference == preferred ? 0 : 1,
      );
      if (byLine != 0) return byLine;
      return a.name.compareTo(b.name);
    });

  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.78,
                ),
                decoration: solidPanelDecoration(radius: 28),
                padding: const EdgeInsets.all(14),
                child: Column(
                  spacing: 12,
                  children: [
                    Text(
                      'Seleziona linea ${nextOnOffense ? 'attacco' : 'difesa'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    Text(
                      '${selected.length}/${match.teamSize} in campo',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: sportMutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: sorted.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final player = sorted[index];
                          return LineupPlayerTile(
                            player: player,
                            selected: selected.contains(player.id),
                            pointsPlayed: getPointsPlayed(player.id),
                            onTap: () {
                              setSheetState(() {
                                if (selected.contains(player.id)) {
                                  selected.remove(player.id);
                                } else if (selected.length < match.teamSize) {
                                  selected.add(player.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    SportFloatingActionButton(
                      label: selected.length == match.teamSize
                          ? 'Start point'
                          : 'Seleziona ${match.teamSize}',
                      icon: FIcons.play,
                      onPressed: selected.length == match.teamSize
                          ? () => Navigator.pop(context, selected)
                          : () {},
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
