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
                      '${player.linePreference?.label ?? 'Nessuna'} · ${player.role.label}',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
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

class InjurySubstitutionDraft {
  const InjurySubstitutionDraft({
    required this.injured,
    required this.replacement,
  });

  final Player injured;
  final Player replacement;
}

class LineupSelectionResult {
  final Set<String> teamAIds;
  final Set<String> teamBIds;
  const LineupSelectionResult({required this.teamAIds, required this.teamBIds});
}

class _TeamTabHeader extends StatelessWidget {
  const _TeamTabHeader({
    required this.label,
    required this.selected,
    required this.count,
    required this.teamSize,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final int count;
  final int teamSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withValues(alpha: 0.20)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          spacing: 8,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.white : sportMutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: count == teamSize
                    ? AppColors.violetLight.withValues(alpha: 0.3)
                    : AppColors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count/$teamSize',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: count == teamSize
                      ? AppColors.violetLight
                      : sportMutedText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<LineupSelectionResult?> showLineSelectionSheet(
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
    final rosterPlayers = allPlayers.where((p) => rosterIds.contains(p.id)).toList();
    return rosterPlayers
      ..sort((a, b) {
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
            final roster = activeTab == 'teamA' ? match.teamARosterIds : match.teamBRosterIds;
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
              ? (selectedA.length == match.teamSize && selectedB.length == match.teamSize)
              : selectedA.length == match.teamSize;

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
                    if (isScrimmage) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TeamTabHeader(
                            label: match.teamAName,
                            selected: activeTab == 'teamA',
                            count: selectedA.length,
                            teamSize: match.teamSize,
                            onTap: () => setSheetState(() => activeTab = 'teamA'),
                          ),
                          const SizedBox(width: 16),
                          _TeamTabHeader(
                            label: match.teamBName,
                            selected: activeTab == 'teamB',
                            count: selectedB.length,
                            teamSize: match.teamSize,
                            onTap: () => setSheetState(() => activeTab = 'teamB'),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        '${selectedA.length}/${match.teamSize} in campo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: sportMutedText,
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
                              child: _SelectableLineupTile(
                                player: player,
                                selected: activeSelection.contains(player.id),
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
                                color: AppColors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: AppColors.white.withValues(
                                    alpha: 0.10,
                                  ),
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
                                              color: AppColors.white,
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
                                            color: sportMutedText,
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(width: 8),
                                    AnimatedRotation(
                                      turns: showOtherLine ? 0.5 : 0,
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      child: const Icon(
                                        FIcons.chevronDown,
                                        color: AppColors.white,
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
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: _SelectableLineupTile(
                                      player: player,
                                      selected: activeSelection.contains(player.id),
                                      pointsPlayed: getPointsPlayed(player.id),
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
          );
        },
      );
    },
  );
}

class _SelectableLineupTile extends StatelessWidget {
  const _SelectableLineupTile({
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

Future<InjurySubstitutionDraft?> showInjurySubstitutionSheet(
  BuildContext context, {
  required List<Player> currentPlayers,
  required List<Player> allPlayers,
}) {
  Player? injured = currentPlayers.isEmpty ? null : currentPlayers.first;
  Player? replacement;

  List<Player> candidatesFor(Player? injuredPlayer) {
    final currentIds = currentPlayers.map((player) => player.id).toSet();
    final candidates = allPlayers
        .where((player) => !currentIds.contains(player.id))
        .toList();
    candidates.sort((a, b) {
      if (injuredPlayer != null) {
        final role = (a.role == injuredPlayer.role ? 0 : 1).compareTo(
          b.role == injuredPlayer.role ? 0 : 1,
        );
        if (role != 0) return role;
        final line = (a.linePreference == injuredPlayer.linePreference ? 0 : 1)
            .compareTo(
              b.linePreference == injuredPlayer.linePreference ? 0 : 1,
            );
        if (line != 0) return line;
      }
      return a.name.compareTo(b.name);
    });
    return candidates;
  }

  return showModalBottomSheet<InjurySubstitutionDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final candidates = candidatesFor(injured);
          if (replacement != null &&
              !candidates.any((player) => player.id == replacement!.id)) {
            replacement = null;
          }
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.82,
                ),
                decoration: solidPanelDecoration(radius: 28),
                padding: const EdgeInsets.all(14),
                child: Column(
                  spacing: 12,
                  children: [
                    Text(
                      'Cambio per infortunio',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    _SubstitutionSection(
                      title: 'Chi esce',
                      players: currentPlayers,
                      selectedId: injured?.id,
                      onSelect: (player) {
                        setSheetState(() {
                          injured = player;
                          replacement = null;
                        });
                      },
                    ),
                    Expanded(
                      child: _SubstitutionSection(
                        title: 'Chi entra',
                        players: candidates,
                        selectedId: replacement?.id,
                        highlightRole: injured?.role,
                        onSelect: (player) {
                          setSheetState(() => replacement = player);
                        },
                      ),
                    ),
                    SportFloatingActionButton(
                      label: injured != null && replacement != null
                          ? 'Conferma cambio'
                          : 'Seleziona cambio',
                      icon: FIcons.plus,
                      onPressed: injured != null && replacement != null
                          ? () => Navigator.pop(
                              context,
                              InjurySubstitutionDraft(
                                injured: injured!,
                                replacement: replacement!,
                              ),
                            )
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

class _SubstitutionSection extends StatelessWidget {
  const _SubstitutionSection({
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
            color: sportMutedText,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (players.isEmpty)
          Text(
            'Nessun giocatore disponibile',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: sportMutedText,
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
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                Text(
                                  '${player.role.label} · ${player.linePreference?.label ?? 'Nessuna'}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: sportMutedText,
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
                                : sportMutedText,
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
