import 'package:flutter/material.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';
import 'package:trio/src/shared/sport_avatar_pill.dart';

class RankingFilters extends StatelessWidget {
  const RankingFilters({
    super.key,
    required this.roleFilter,
    required this.lineFilter,
    required this.onRoleChanged,
    required this.onLineChanged,
  });

  final PlayerRole? roleFilter;
  final PlayerLinePreference? lineFilter;
  final ValueChanged<PlayerRole?> onRoleChanged;
  final ValueChanged<PlayerLinePreference?> onLineChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        spacing: 8,
        children: [
          SportFilterPill(
            label: 'Handler',
            selected: roleFilter == PlayerRole.handler,
            onPressed: () => onRoleChanged(
              roleFilter == PlayerRole.handler ? null : PlayerRole.handler,
            ),
          ),
          SportFilterPill(
            label: 'Cutter',
            selected: roleFilter == PlayerRole.cutter,
            onPressed: () => onRoleChanged(
              roleFilter == PlayerRole.cutter ? null : PlayerRole.cutter,
            ),
          ),
          SportFilterPill(
            label: 'Attacco',
            selected: lineFilter == PlayerLinePreference.offense,
            onPressed: () => onLineChanged(
              lineFilter == PlayerLinePreference.offense
                  ? null
                  : PlayerLinePreference.offense,
            ),
          ),
          SportFilterPill(
            label: 'Difesa',
            selected: lineFilter == PlayerLinePreference.defense,
            onPressed: () => onLineChanged(
              lineFilter == PlayerLinePreference.defense
                  ? null
                  : PlayerLinePreference.defense,
            ),
          ),
        ],
      ),
    );
  }
}
