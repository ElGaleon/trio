import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/final_stats_summary.dart';
import 'package:trio/src/features/matches/domain/individual_stat_line.dart';
import 'package:trio/src/common_widgets/sport_avatar_pill.dart';
import 'package:trio/src/common_widgets/sport_screen_shell.dart';
import 'package:trio/src/common_widgets/sport_glass_decoration_helper.dart';

class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.black.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          spacing: 2,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: sportMutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderCard extends StatelessWidget {
  const LeaderCard({
    super.key,
    required this.label,
    required this.names,
    required this.value,
    required this.icon,
    required this.valueSuffix,
  });

  final String label;
  final String names;
  final String value;
  final IconData icon;
  final String valueSuffix;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          spacing: 12,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.violet.withValues(alpha: 0.3)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(icon, color: AppColors.white, size: 16),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    names,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '$label · $value $valueSuffix',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

(String, String)? parseLeader(String leaderRaw) {
  if (leaderRaw == '-' || leaderRaw.trim().isEmpty) return null;
  final openParen = leaderRaw.lastIndexOf('(');
  final closeParen = leaderRaw.lastIndexOf(')');
  if (openParen == -1 || closeParen == -1 || closeParen <= openParen) {
    return (leaderRaw, '');
  }
  final names = leaderRaw.substring(0, openParen).trim();
  final value = leaderRaw.substring(openParen + 1, closeParen).trim();
  return (names, value);
}

class GroupedStatsBlock extends StatelessWidget {
  const GroupedStatsBlock({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 24),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: children),
          ],
        ),
      ),
    );
  }
}

class IndividualStatCard extends StatelessWidget {
  const IndividualStatCard({super.key, required this.row});

  final IndividualStatLine row;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          spacing: 10,
          children: [
            SportPlayerAvatar(
              initials: row.player.initials,
              imagePath: row.player.profileImagePath,
              size: 42,
            ),
            Expanded(
              child: Column(
                spacing: 6,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'M ${row.goals} · A ${row.assists} · T ${row.touches} · D ${row.defenses} · E ${row.errors} · PT ${row.pointsPlayed}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: sportMutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.violet),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Text(
                  row.rating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IndividualStatsTab extends StatelessWidget {
  const IndividualStatsTab({
    super.key,
    required this.match,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final rows = IndividualStatLine.from(match, playersById);
    final summary = FinalStatsSummary.from(match, playersById);
    final scorer = parseLeader(summary.topScorer);
    final assistant = parseLeader(summary.mostAssist);
    final touches = parseLeader(summary.mostTouches);
    final defender = parseLeader(summary.bestDefender);
    final presence = parseLeader(summary.mostPlayed);

    final hasLeaders = scorer != null || assistant != null || touches != null || defender != null || presence != null;

    return Column(
      spacing: 12,
      children: [
        if (hasLeaders)
          GroupedStatsBlock(
            title: 'Leader',
            children: [
              Column(
                spacing: 8,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (scorer != null)
                    LeaderCard(
                      label: 'Top Scorer',
                      names: scorer.$1,
                      value: scorer.$2,
                      icon: FIcons.flag,
                      valueSuffix: scorer.$2 == '1' ? 'meta' : 'meta',
                    ),
                  if (assistant != null)
                    LeaderCard(
                      label: 'Most Assist',
                      names: assistant.$1,
                      value: assistant.$2,
                      icon: FIcons.arrowRight,
                      valueSuffix: assistant.$2 == '1' ? 'assist' : 'assist',
                    ),
                  if (touches != null)
                    LeaderCard(
                      label: 'Most Touches',
                      names: touches.$1,
                      value: touches.$2,
                      icon: FIcons.activity,
                      valueSuffix: touches.$2 == '1' ? 'tocco' : 'tocchi',
                    ),
                  if (defender != null)
                    LeaderCard(
                      label: 'Best Defender',
                      names: defender.$1,
                      value: defender.$2,
                      icon: FIcons.shield,
                      valueSuffix: defender.$2 == '1' ? 'difesa' : 'difese',
                    ),
                  if (presence != null)
                    LeaderCard(
                      label: 'Most Played',
                      names: presence.$1,
                      value: presence.$2,
                      icon: FIcons.timer,
                      valueSuffix: presence.$2 == '1' ? 'punto' : 'punti',
                    ),
                ],
              ),
            ],
          ),
        GroupedStatsBlock(
          title: 'Punti giocati',
          children: [
            if (summary.pointsPlayed.isEmpty)
              const StatPill(label: 'Nessun dato', value: '-')
            else
              for (final item in summary.pointsPlayed)
                StatPill(label: item.name, value: '${item.value} pt'),
          ],
        ),
        DecoratedBox(
          decoration: sportGlassDecoration(radius: 28),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              spacing: 12,
              children: [
                Text(
                  'Performance Giocatori',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (rows.isEmpty)
                  Text(
                    'Nessun giocatore tracciato',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: sportMutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                else
                  for (final row in rows) IndividualStatCard(row: row),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
