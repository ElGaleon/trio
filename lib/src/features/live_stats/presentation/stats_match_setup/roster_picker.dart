import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/shared/sport_player_avatar.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';

class RosterPicker extends StatefulWidget {
  const RosterPicker({
    super.key,
    required this.players,
    required this.selectedIds,
    required this.minimum,
    required this.preferredLine,
    required this.onToggle,
    this.maximum,
    this.title = 'Presenti',
  });

  final List<Player> players;
  final Set<String> selectedIds;
  final int minimum;
  final GameLine preferredLine;
  final ValueChanged<String> onToggle;
  final int? maximum;
  final String title;

  @override
  State<RosterPicker> createState() => _RosterPickerState();
}

class _RosterPickerState extends State<RosterPicker> {
  bool _showOtherLine = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final preferredPlayers = widget.players
        .where((player) => player.linePreference == widget.preferredLine)
        .toList();
    final otherPlayers = widget.players
        .where((player) => player.linePreference != widget.preferredLine)
        .toList();
    final otherLineLabel = widget.preferredLine == GameLine.offense
        ? GameLine.defense.label
        : GameLine.offense.label;

    return GlassDecoration(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          spacing: 12,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.title} · ${widget.preferredLine.label}',
                    style: textTheme.titleMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  widget.maximum == null
                      ? '${widget.selectedIds.length}/${widget.minimum} min'
                      : '${widget.selectedIds.length}/${widget.maximum}',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            for (final player in preferredPlayers) _rosterTile(player: player),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _showOtherLine = !_showOtherLine),
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
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.sportForeground(context),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${otherPlayers.where((player) => widget.selectedIds.contains(player.id)).length}/${otherPlayers.length}',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.sportMutedForeground(context),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedRotation(
                        turns: _showOtherLine ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          FIcons.chevronDown,
                          color: AppColors.sportForeground(context),
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
                    _rosterTile(player: player),
                ],
              ),
              crossFadeState: _showOtherLine
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 180),
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _rosterTile({required Player player}) {
    final textTheme = Theme.of(context).textTheme;
    final selected = widget.selectedIds.contains(player.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onToggle(player.id),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? AppColors.violet.withValues(alpha: 0.22)
                : AppColors.white.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppColors.violet
                  : AppColors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              spacing: 10,
              children: [
                SportPlayerAvatar(
                  initials: player.initials,
                  imagePath: player.profileImagePath,
                  size: 38,
                ),
                Expanded(
                  child: Text(
                    player.name,
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  selected ? FIcons.check : FIcons.plus,
                  color: selected
                      ? AppColors.violetLight
                      : AppColors.sportMutedText,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
