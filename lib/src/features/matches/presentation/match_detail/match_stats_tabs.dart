import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/matches/domain/match_stat_type.dart';
import 'package:skrim/src/features/matches/domain/match_stat_event.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/features/matches/domain/final_stats_summary.dart';
import 'package:skrim/src/features/matches/domain/individual_stat_line.dart';
import 'package:skrim/src/features/matches/application/match_detail_provider.dart';
import 'package:skrim/src/shared/sport_avatar_pill.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'grouped_match_stats.dart';
import 'individual_stats_tab.dart';
import 'timeline_tab.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/features/matches/domain/match_detail_tab.dart';

class StatsTabButton extends StatelessWidget {
  const StatsTabButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 22, bottom: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: selected ? AppColors.white : sportMutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 36 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.violetLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MatchStatsTabBar extends ConsumerWidget {
  const MatchStatsTabBar({super.key, required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(matchDetailTabProvider(match.id));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: MatchDetailTab.values.map((tab) {
          return StatsTabButton(
            label: tab.label,
            selected: tab == selectedTab,
            onTap: () =>
                ref.read(matchDetailTabProvider(match.id).notifier).setTab(tab),
          );
        }).toList(),
      ),
    );
  }
}

class MatchStatsTabContent extends ConsumerWidget {
  const MatchStatsTabContent({
    super.key,
    required this.match,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(matchDetailTabProvider(match.id));
    final summary = FinalStatsSummary.from(match, playersById);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: switch (selectedTab) {
        MatchDetailTab.facts => FactsTab(
          key: const ValueKey('facts'),
          match: match,
          summary: summary,
          playersById: playersById,
        ),
        MatchDetailTab.timeline => TimelineTab(
          key: const ValueKey('timeline'),
          match: match,
          playersById: playersById,
        ),
        MatchDetailTab.team => GroupedMatchStats(
          key: const ValueKey('team'),
          match: match,
          playersById: playersById,
        ),
        MatchDetailTab.individual => IndividualStatsTab(
          key: const ValueKey('individual'),
          match: match,
          playersById: playersById,
        ),
      },
    );
  }
}

class SplitBar extends StatelessWidget {
  const SplitBar({
    super.key,
    required this.leftPercent,
    required this.leftLabel,
    required this.rightLabel,
  });

  final double leftPercent;
  final String leftLabel;
  final String rightLabel;

  @override
  Widget build(BuildContext context) {
    final clamped = leftPercent.clamp(0.05, 0.95);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 54,
        child: Row(
          children: [
            Expanded(
              flex: (clamped * 100).round(),
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 18),
                color: AppColors.violet,
                child: Text(
                  leftLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: ((1 - clamped) * 100).round(),
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 18),
                color: AppColors.danger,
                child: Text(
                  rightLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.sportForeground(context),
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

class RoundMetric extends StatelessWidget {
  const RoundMetric({super.key, required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.violet,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.sportForeground(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class DualMetricRow extends StatelessWidget {
  const DualMetricRow({
    super.key,
    required this.left,
    required this.label,
    required this.right,
  });

  final String left;
  final String label;
  final String right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          RoundMetric(value: left),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            right,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.sportForeground(context),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class BestPlayerCard extends StatelessWidget {
  const BestPlayerCard({
    super.key,
    required this.match,
    required this.summary,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final FinalStatsSummary summary;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final rows = IndividualStatLine.from(match, playersById);
    final bestRow = rows.isEmpty ? null : rows.first;
    final player = bestRow?.player;
    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 16,
          children: [
            Text(
              "Miglior giocatore dell'incontro",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              spacing: 12,
              children: [
                SportPlayerAvatar(
                  initials: player?.initials ?? '?',
                  imagePath: player?.profileImagePath,
                  size: 48,
                ),
                Expanded(
                  child: Text(
                    player?.name ?? '-',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.violet),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Text(
                      bestRow?.rating.toStringAsFixed(1) ?? '-',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MiniTimeline extends StatelessWidget {
  const MiniTimeline({
    super.key,
    required this.events,
    required this.match,
    required this.playersById,
  });

  final List<MatchStatEvent> events;
  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          children: [
            Text(
              'Eventi recenti',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            if (events.isEmpty)
              Text(
                'Nessun evento',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: sportMutedText,
                  fontWeight: FontWeight.w800,
                ),
              )
            else
              for (final event in events)
                TimelineEventRow(
                  event: event,
                  match: match,
                  playersById: playersById,
                ),
          ],
        ),
      ),
    );
  }
}

class FactsTab extends StatelessWidget {
  const FactsTab({
    super.key,
    required this.match,
    required this.summary,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final FinalStatsSummary summary;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final opponentGoals = match.statEvents
        .where((event) => event.type == MatchStatType.opponentGoal)
        .length;
    final totalGoals = summary.goals + opponentGoals;
    final ourGoalShare = totalGoals == 0 ? 0.5 : summary.goals / totalGoals;
    final recentEvents = match.statEvents
        .where((event) => event.type != MatchStatType.lineup)
        .toList()
        .reversed
        .take(4)
        .toList();
    return Column(
      spacing: 12,
      children: [
        GlassDecoration(
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Statistiche top',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Share mete',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                SplitBar(
                  leftPercent: ourGoalShare,
                  leftLabel: '${(ourGoalShare * 100).round()}%',
                  rightLabel: '${((1 - ourGoalShare) * 100).round()}%',
                ),
                DualMetricRow(
                  left: '${summary.goals}',
                  label: 'Mete',
                  right: '$opponentGoals',
                ),
                DualMetricRow(
                  left: '${summary.goals + summary.breaks}',
                  label: 'Azioni positive',
                  right: '${summary.turnovers}',
                ),
                DualMetricRow(
                  left: summary.percent(summary.passAccuracy),
                  label: 'Pass accuracy',
                  right: '${summary.turnovers} TO',
                ),
              ],
            ),
          ),
        ),
        BestPlayerCard(
          match: match,
          summary: summary,
          playersById: playersById,
        ),
        MiniTimeline(
          events: recentEvents,
          match: match,
          playersById: playersById,
        ),
      ],
    );
  }
}

class MatchStatsTabs extends ConsumerWidget {
  const MatchStatsTabs({
    super.key,
    required this.match,
    required this.playersById,
  });

  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 14,
      children: [
        MatchStatsTabBar(match: match),
        MatchStatsTabContent(match: match, playersById: playersById),
      ],
    );
  }
}
