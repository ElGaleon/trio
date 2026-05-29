import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../models/scrimmage_match.dart';
import 'card_actions_menu.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  final ScrimmageMatch match;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    FIcons.calendarDays,
                    size: 15,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(_dateLabel(match.createdAt), style: textTheme.bodySmall),
                  const Spacer(),
                  CardActionsMenu(onEdit: onEdit, onDelete: onDelete),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [

                  Expanded(
                    child: _TeamScoreBadge(
                      name: match.teamAName,
                      score: match.scoreA,
                      highlighted: !match.isDraw && match.teamAWon,
                      alignEnd: false,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Text(
                          '-',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        FBadge(
                          variant: match.isDraw ? .secondary : .outline,
                          child: Text('${match.teamSize}v${match.teamSize}'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _TeamScoreBadge(
                      name: match.teamBName,
                      score: match.scoreB,
                      highlighted: !match.isDraw && !match.teamAWon,
                      alignEnd: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    match.offenseVsDefense ? FIcons.shield : FIcons.users,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    match.offenseVsDefense
                        ? 'Attacco vs difesa'
                        : 'Squadre libere',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamScoreBadge extends StatelessWidget {
  const _TeamScoreBadge({
    required this.name,
    required this.score,
    required this.highlighted,
    required this.alignEnd,
  });

  final String name;
  final int score;
  final bool highlighted;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final children = [
      /*_TeamLogo(name: name, highlighted: highlighted),*/
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: alignEnd
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              _shortLabel(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: alignEnd ? TextAlign.end : TextAlign.start,
              style: textTheme.titleSmall?.copyWith(
                color: highlighted ? colorScheme.primary : null,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              highlighted ? 'Winner' : 'Team',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score.toDouble()),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Text(
            value.round().toString(),
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          );
        },
      ),
    ];

    return Row(children: alignEnd ? children.reversed.toList() : children);
  }
}

class _TeamLogo extends StatelessWidget {
  const _TeamLogo({required this.name, required this.highlighted});

  final String name;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: highlighted
            ? colorScheme.primary.withValues(alpha: 0.14)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Icon(
        _teamIcon(name),
        color: highlighted ? colorScheme.primary : colorScheme.onSurface,
      ),
    );
  }
}

IconData _teamIcon(String name) {
  const icons = [
    FIcons.flame,
    FIcons.bolt,
    FIcons.shield,
    FIcons.star,
    FIcons.circleDot,
    FIcons.cloudLightning,
    FIcons.gem,
    FIcons.badgeCheck,
  ];
  final seed = name.runes.fold<int>(0, (value, rune) => value + rune);
  return icons[seed % icons.length];
}

String _shortLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.length <= 8) return trimmed;
  return trimmed.substring(0, 8);
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
