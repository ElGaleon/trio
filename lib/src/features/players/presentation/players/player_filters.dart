import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';
import 'package:trio/src/shared/sport_avatar_pill.dart';

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
  final PlayerLinePreference? lineFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PlayerRole?> onRoleChanged;
  final ValueChanged<PlayerLinePreference?> onLineChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 8,
      children: [
        FTextFormField(
          control: FTextFieldControl.managed(
            controller: searchController,
            onChange: (value) => onSearchChanged(value.text),
          ),
          prefixBuilder: (context, style, states) => const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(FIcons.search, size: 15),
          ),
          hint: 'Cerca giocatore',
        ),
        SingleChildScrollView(
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
        ),
      ],
    );
  }
}
