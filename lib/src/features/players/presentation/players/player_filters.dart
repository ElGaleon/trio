import 'package:flutter/material.dart';
import 'package:skrim/src/components/ui/searchbar.dart';

import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'package:skrim/src/features/players/domain/player_role.dart';
import 'package:skrim/src/shared/sport_avatar_pill.dart';

class PlayerFilters extends StatelessWidget {
  const PlayerFilters({
    super.key,
    required this.searchController,
    required this.roleFilter,
    required this.lineFilter,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onLineChanged,
  });

  final TextEditingController searchController;
  final PlayerRole? roleFilter;
  final GameLine? lineFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PlayerRole?> onRoleChanged;
  final ValueChanged<GameLine?> onLineChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Searchbar(
          label: 'Player',
          hint: 'Search player',
          onChange: (value) => onSearchChanged(value),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              ...PlayerRole.values.map((role) => SportFilterPill(
                label: role.label,
                selected: roleFilter == role,
                onPressed: () => onRoleChanged(
                  roleFilter == role ? null : role,
                ),
              ),),

              ...GameLine.values.map((line) => SportFilterPill(
                label: line.label,
                selected: lineFilter == line,
                onPressed: () => onLineChanged(
                  lineFilter == line ? null : line,
                ),
              ),)
            ],
          ),
        ),
      ],
    );
  }
}
