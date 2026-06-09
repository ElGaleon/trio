import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../model/player.dart';
import '../../providers/elo_providers.dart';
import 'recent_teams_picker.dart';

class PresenceStep extends StatelessWidget {
  const PresenceStep({
    super.key,
    required this.title,
    required this.description,
    required this.count,
    required this.minimum,
    required this.players,
    required this.recentTeams,
    required this.selectedIds,
    required this.disabledIds,
    required this.onChanged,
    required this.onApplyRecentTeam,
    this.suggestedLine,
  });

  final String title;
  final String description;
  final int count;
  final int minimum;
  final List<Player> players;
  final List<RecentMatchTeam> recentTeams;
  final Set<String> selectedIds;
  final Set<String> disabledIds;
  final ValueChanged<String> onChanged;
  final ValueChanged<RecentMatchTeam> onApplyRecentTeam;
  final PlayerLinePreference? suggestedLine;

  @override
  Widget build(BuildContext context) {
    final visiblePlayers = players.where((player) {
      if (suggestedLine == null) return true;
      if (disabledIds.contains(player.id)) return false;
      return player.linePreference == suggestedLine;
    }).toList();

    final sortedPlayers = visiblePlayers
      ..sort((a, b) {
        final aSuggested = a.linePreference == suggestedLine ? 0 : 1;
        final bSuggested = b.linePreference == suggestedLine ? 0 : 1;
        final byLine = aSuggested.compareTo(bSuggested);
        if (byLine != 0) return byLine;
        return a.name.compareTo(b.name);
      });

    return FCard(
      title: Row(
        spacing: 8,
        children: [
          Expanded(child: Text(title)),
          FBadge(
            variant: count >= minimum ? .primary : .outline,
            child: Text('$count/$minimum min'),
          ),
        ],
      ),
      subtitle: Text(description),
      child: Column(
        spacing: 12,
        children: [
          if (recentTeams.isNotEmpty)
            RecentTeamsPicker(
              recentTeams: recentTeams,
              selectedIds: selectedIds,
              onApplyRecentTeam: onApplyRecentTeam,
            ),
          FTileGroup(
            children: [
              ...sortedPlayers.map((player) {
                final selected = selectedIds.contains(player.id);
                final disabled = disabledIds.contains(player.id);
                return FTile(
                  enabled: !disabled,
                  selected: selected,
                  prefix: Icon(_lineIcon(player.linePreference)),
                  title: Text(player.name),
                  subtitle: Text(
                    '${player.role.label} · ${player.linePreference?.label ?? 'Nessuna'}',
                  ),
                  suffix: selected
                      ? const Icon(FIcons.check, size: 18)
                      : disabled
                      ? const Icon(FIcons.x, size: 18)
                      : null,
                  onPress: disabled ? null : () => onChanged(player.id),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  IconData _lineIcon(PlayerLinePreference? linePreference) {
    return switch (linePreference) {
      PlayerLinePreference.offense => FIcons.arrowUpRight,
      PlayerLinePreference.defense => FIcons.shield,
      null => FIcons.user,
    };
  }
}
