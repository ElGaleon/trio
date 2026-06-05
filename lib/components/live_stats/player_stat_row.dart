import 'package:flutter/material.dart';
import '../../model/player.dart';
import '../../model/scrimmage_match.dart';
import '../../theme/app_colors.dart';
import '../shared/sport_screen_shell.dart';

class StatButton extends StatelessWidget {
  const StatButton({
    super.key,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: (destructive ? AppColors.danger : AppColors.violet).withValues(
            alpha: 0.20,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: destructive ? AppColors.danger : AppColors.violet,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerStatRow extends StatelessWidget {
  const PlayerStatRow({
    super.key,
    required this.player,
    required this.enabledStatTypes,
    required this.oursOnOffense,
    required this.hasDisc,
    required this.noDiscHolder,
    required this.onEvent,
  });

  final Player player;
  final List<MatchStatType> enabledStatTypes;
  final bool oursOnOffense;
  final bool hasDisc;
  final bool noDiscHolder;
  final ValueChanged<MatchStatType> onEvent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: hasDisc
            ? AppColors.violet.withValues(alpha: 0.10)
            : AppColors.transparent,
        border: Border(
          bottom: BorderSide(color: AppColors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 7),
        child: Row(
          spacing: 8,
          children: [
            SizedBox(
              width: 112,
              child: Row(
                spacing: 8,
                children: [
                  Text(
                    _numberLabel(player),
                    style: textTheme.titleLarge?.copyWith(
                      color: sportMutedText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          hasDisc ? 'disco' : player.role.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: hasDisc
                                ? AppColors.violetLight
                                : sportMutedText,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: Row(
                  spacing: 6,
                  children: _buttons(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buttons() {
    final enabled = enabledStatTypes.toSet();
    final actions = oursOnOffense
        ? hasDisc
              ? [
                  ('TE', MatchStatType.throwError, true),
                  ('S', MatchStatType.stallOut, true),
                ]
              : noDiscHolder
              ? [
                  ('C', MatchStatType.catchDisc, false),
                  ('RE', MatchStatType.catchError, true),
                ]
              : [
                  ('P', MatchStatType.pass, false),
                  ('H', MatchStatType.huck, false),
                  ('RE', MatchStatType.catchError, true),
                ]
        : [
            ('S', MatchStatType.stallOut, false),
            ('C', MatchStatType.catchDisc, false),
            ('B', MatchStatType.block, false),
            ('A', MatchStatType.openError, true),
            ('BU', MatchStatType.deepError, true),
            ('R', MatchStatType.resetError, true),
          ];

    final visibleActions = actions
        .where((action) => enabled.contains(action.$2))
        .toList(growable: false);
    if (visibleActions.isEmpty) {
      return [
        const Text(
          'Nessuna stat',
          style: TextStyle(
            color: sportMutedText,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
      ];
    }
    return [
      for (final action in visibleActions)
        StatButton(
          label: action.$1,
          destructive: action.$3,
          onTap: () => onEvent(action.$2),
        ),
    ];
  }

  String _numberLabel(Player player) {
    return ((player.id.hashCode.abs() % 98) + 1).toString();
  }
}
