import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:skrim/src/shared/decorated_panel.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'lineup_selection_result.dart';
import 'selectable_lineup_tile.dart';
import 'team_tab_header.dart';

class LineSelectionSheet {
  const LineSelectionSheet._();

  static Future<LineupSelectionResult?> show(
    BuildContext context, {
    required ScrimmageMatch match,
    required List<Player> allPlayers,
    required int Function(String playerId) getPointsPlayed,
    required bool nextOnOffense,
  }) {
    final preferred = nextOnOffense
        ? PlayerLinePreference.offense
        : PlayerLinePreference.defense;

    final selectedA = match.teamAIds.toSet();
    final selectedB = match.teamBIds.toSet();
    var activeTab = 'teamA';

    List<Player> getSortedTeamPlayers(List<String> rosterIds) {
      final rosterPlayers = allPlayers
          .where((p) => rosterIds.contains(p.id))
          .toList();
      return rosterPlayers..sort((a, b) {
        final byLine = (a.linePreference == preferred ? 0 : 1).compareTo(
          b.linePreference == preferred ? 0 : 1,
        );
        if (byLine != 0) return byLine;
        return a.name.compareTo(b.name);
      });
    }

    final sortedPlayers = [...allPlayers]
      ..sort((a, b) {
        final byLine = (a.linePreference == preferred ? 0 : 1).compareTo(
          b.linePreference == preferred ? 0 : 1,
        );
        if (byLine != 0) return byLine;
        return a.name.compareTo(b.name);
      });

    var showOtherLine = false;

    return showModalBottomSheet<LineupSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isScrimmage = !match.isExternalOpponent;

            List<Player> visiblePlayers;
            Set<String> activeSelection;
            if (isScrimmage) {
              final roster = activeTab == 'teamA'
                  ? match.teamARosterIds
                  : match.teamBRosterIds;
              visiblePlayers = getSortedTeamPlayers(roster);
              activeSelection = activeTab == 'teamA' ? selectedA : selectedB;
            } else {
              visiblePlayers = sortedPlayers;
              activeSelection = selectedA;
            }

            final preferredPlayers = visiblePlayers
                .where((player) => player.linePreference == preferred)
                .toList();
            final otherPlayers = visiblePlayers
                .where((player) => player.linePreference != preferred)
                .toList();
            final otherLineLabel = preferred == PlayerLinePreference.offense
                ? PlayerLinePreference.defense.label
                : PlayerLinePreference.offense.label;

            final canSubmit = isScrimmage
                ? (selectedA.length == match.teamSize &&
                      selectedB.length == match.teamSize)
                : selectedA.length == match.teamSize;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedPanel(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      spacing: 12,
                      children: [
                        Text(
                          'Seleziona linea ${nextOnOffense ? 'attacco' : 'difesa'}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.sportForeground(context),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        if (isScrimmage) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TeamTabHeader(
                                label: match.teamAName,
                                selected: activeTab == 'teamA',
                                count: selectedA.length,
                                teamSize: match.teamSize,
                                onTap: () =>
                                    setSheetState(() => activeTab = 'teamA'),
                              ),
                              const SizedBox(width: 16),
                              TeamTabHeader(
                                label: match.teamBName,
                                selected: activeTab == 'teamB',
                                count: selectedB.length,
                                teamSize: match.teamSize,
                                onTap: () =>
                                    setSheetState(() => activeTab = 'teamB'),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            '${selectedA.length}/${match.teamSize} in campo',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.sportMutedForeground(
                                    context,
                                  ),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                        Expanded(
                          child: ListView(
                            children: [
                              for (final player in preferredPlayers)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: SelectableLineupTile(
                                    player: player,
                                    selected: activeSelection.contains(
                                      player.id,
                                    ),
                                    pointsPlayed: getPointsPlayed(player.id),
                                    selectedIds: activeSelection,
                                    teamSize: match.teamSize,
                                    onChanged: setSheetState,
                                  ),
                                ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setSheetState(() {
                                    showOtherLine = !showOtherLine;
                                  });
                                },
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.sportForeground(
                                      context,
                                    ).withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AppColors.sportForeground(
                                        context,
                                      ).withValues(alpha: 0.10),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 11,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Giocatori $otherLineLabel',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      AppColors.sportForeground(
                                                        context,
                                                      ),
                                                  fontWeight: FontWeight.w900,
                                                ),
                                          ),
                                        ),
                                        Text(
                                          '${otherPlayers.where((player) => activeSelection.contains(player.id)).length}/${otherPlayers.length}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AppColors.sportMutedForeground(
                                                      context,
                                                    ),
                                                fontWeight: FontWeight.w900,
                                              ),
                                        ),
                                        const SizedBox(width: 8),
                                        AnimatedRotation(
                                          turns: showOtherLine ? 0.5 : 0,
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          child: Icon(
                                            FIcons.chevronDown,
                                            color: AppColors.sportForeground(
                                              context,
                                            ),
                                            size: 18,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox.shrink(),
                                secondChild: Column(
                                  children: [
                                    const SizedBox(height: 8),
                                    for (final player in otherPlayers)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: SelectableLineupTile(
                                          player: player,
                                          selected: activeSelection.contains(
                                            player.id,
                                          ),
                                          pointsPlayed: getPointsPlayed(
                                            player.id,
                                          ),
                                          selectedIds: activeSelection,
                                          teamSize: match.teamSize,
                                          onChanged: setSheetState,
                                        ),
                                      ),
                                  ],
                                ),
                                crossFadeState: showOtherLine
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 180),
                                sizeCurve: Curves.easeOutCubic,
                              ),
                            ],
                          ),
                        ),
                        SportFloatingActionButton(
                          label: canSubmit
                              ? 'Start point'
                              : isScrimmage
                              ? 'Seleziona ${match.teamSize} per team'
                              : 'Seleziona ${match.teamSize}',
                          icon: FIcons.play,
                          onPressed: canSubmit
                              ? () => Navigator.pop(
                                  context,
                                  LineupSelectionResult(
                                    teamAIds: selectedA,
                                    teamBIds: selectedB,
                                  ),
                                )
                              : () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
