import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trio/src/shared/sport_glass_decoration.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';

import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/theme/app_colors.dart';

String matchHeroTag(String matchId) => 'match-card-$matchId';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  final ScrimmageMatch match;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: matchHeroTag(match.id),
        flightShuttleBuilder:
            (
              flightContext,
              animation,
              flightDirection,
              fromHeroContext,
              toHeroContext,
            ) {
              final destination = toHeroContext.widget as Hero;
              return Material(
                color: AppColors.transparent,
                child: destination.child,
              );
            },
        child: Material(
          color: AppColors.transparent,
          child: SportGlassDecoration(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  /*
                  Row(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.end,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      CardActionsMenu(onEdit: onEdit, onDelete: onDelete),
                    ],
                  ),
                   */
                  Row(
                    spacing: 4,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(
                        FIcons.calendarDays,
                        size: 16,
                        color: AppColors.violet,
                      ),
                      Text(
                        _dateLabel(match.createdAt),
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.sportMutedText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TeamScoreBadge(
                          name: match.teamAName,
                          score: match.scoreA,
                          highlighted: !match.isDraw && match.teamAWon,
                          alignEnd: false,
                        ),
                      ),
                      MetaData(
                        metaData: 'match score',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Column(
                            spacing: 4,
                            children: [
                              Text(
                                '-',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              FBadge(
                                variant: match.isDraw ? .secondary : .outline,
                                child: Text(
                                  '${match.teamSize}v${match.teamSize}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: AppColors.sportMutedText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: TeamScoreBadge(
                          name: match.teamBName,
                          score: match.scoreB,
                          highlighted: !match.isDraw && !match.teamAWon,
                          alignEnd: true,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    spacing: 6,
                    children: [
                      Icon(
                        match.offenseVsDefense ? FIcons.shield : FIcons.users,
                        size: 15,
                        color: AppColors.sportMutedText,
                      ),
                      Text(
                        match.offenseVsDefense
                            ? 'Attacco vs difesa'
                            : 'Squadre libere',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.sportMutedText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MatchScoreHeroPanel extends StatelessWidget {
  const MatchScoreHeroPanel({
    super.key,
    required this.match,
    this.showMeta = true,
    this.framed = true,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 14),
  });

  final ScrimmageMatch match;
  final bool showMeta;
  final bool framed;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final content = Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          if (showMeta)
            Row(
              spacing: 6,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FIcons.calendarDays, size: 16, color: AppColors.violet),
                Text(
                  _dateLabel(match.createdAt),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: TeamScoreBadge(
                  name: match.teamAName,
                  score: match.scoreA,
                  highlighted: !match.isDraw && match.teamAWon,
                  alignEnd: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  spacing: 4,
                  children: [
                    Text(
                      '-',
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
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
                child: TeamScoreBadge(
                  name: match.teamBName,
                  score: match.scoreB,
                  highlighted: !match.isDraw && !match.teamAWon,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (showMeta)
            Row(
              spacing: 6,
              children: [
                Icon(
                  match.offenseVsDefense ? FIcons.shield : FIcons.users,
                  size: 15,
                  color: AppColors.sportMutedText,
                ),
                Text(
                  match.offenseVsDefense
                      ? 'Attacco vs difesa'
                      : 'Squadre libere',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return Material(
      color: AppColors.transparent,
      child: framed ? GlassDecoration(child: content) : content,
    );
  }
}

class TeamScoreBadge extends StatelessWidget {
  const TeamScoreBadge({
    super.key,
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
    return Column(
      spacing: 4,
      children: [
        TeamLogo(name: name, highlighted: highlighted),
        Text(
          '$score',
          style: textTheme.headlineSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: textTheme.titleSmall?.copyWith(
            color: highlighted ? AppColors.violet : AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          '$score',
          style: textTheme.headlineMedium?.copyWith(
            color: highlighted ? AppColors.violet : AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class TeamLogo extends StatelessWidget {
  const TeamLogo({super.key, required this.name, required this.highlighted});

  final String name;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.violet.withValues(alpha: 0.18)
            : AppColors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted
              ? AppColors.violet
              : AppColors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Icon(
        _teamIcon(name),
        color: highlighted ? AppColors.violet : AppColors.white,
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

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
