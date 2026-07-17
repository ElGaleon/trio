import 'package:flutter/material.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'lineup_player_tile.dart';

class SelectableLineupTile extends StatelessWidget {
  const SelectableLineupTile({
    super.key,
    required this.player,
    required this.selected,
    required this.pointsPlayed,
    required this.selectedIds,
    required this.teamSize,
    required this.onChanged,
  });

  final Player player;
  final bool selected;
  final int pointsPlayed;
  final Set<String> selectedIds;
  final int teamSize;
  final void Function(VoidCallback fn) onChanged;

  @override
  Widget build(BuildContext context) {
    return LineupPlayerTile(
      player: player,
      selected: selected,
      pointsPlayed: pointsPlayed,
      onTap: () {
        onChanged(() {
          if (selectedIds.contains(player.id)) {
            selectedIds.remove(player.id);
          } else if (selectedIds.length < teamSize) {
            selectedIds.add(player.id);
          }
        });
      },
    );
  }
}
