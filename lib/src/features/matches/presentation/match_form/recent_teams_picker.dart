import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/features/matches/application/recent_match_team.dart';

class RecentTeamsPicker extends StatelessWidget {
  const RecentTeamsPicker({
    super.key,
    required this.recentTeams,
    required this.selectedIds,
    required this.onApplyRecentTeam,
  });

  final List<RecentMatchTeam> recentTeams;
  final Set<String> selectedIds;
  final ValueChanged<RecentMatchTeam> onApplyRecentTeam;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          spacing: 8,
          children: [
            Icon(FIcons.history, size: 16, color: colorScheme.primary),
            Text(
              'Squadre di oggi',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
        ),
        FTileGroup(
          children: [
            ...recentTeams.map((team) {
              final selected = _hasSameMembers(selectedIds, team.playerIds);
              return FTile(
                selected: selected,
                prefix: Icon(FIcons.zap, size: 18),
                title: Text(team.name),
                subtitle: Text(team.playerNames.join(', ')),
                details: FBadge(
                  variant: selected ? .primary : .secondary,
                  child: Text('${team.playerIds.length}'),
                ),
                suffix: selected ? Icon(FIcons.check, size: 18) : null,
                onPress: () => onApplyRecentTeam(team),
              );
            }),
          ],
        ),
      ],
    );
  }

  bool _hasSameMembers(Set<String> selectedIds, List<String> teamIds) {
    if (selectedIds.length != teamIds.length) return false;
    return teamIds.every(selectedIds.contains);
  }
}
