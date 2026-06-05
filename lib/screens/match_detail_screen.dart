import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/providers/match_provider.dart';

import '../app_router.dart';
import '../components/shared/app_empty_state.dart';
import '../components/shared/match_card.dart';
import '../components/shared/sport_avatar_pill.dart';
import '../components/shared/sport_screen_shell.dart';
import '../components/match_detail/score_trend_chart.dart';
import '../components/match_detail/team_block.dart';
import '../components/match_detail/pre_match_block.dart';
import '../components/match_detail/rating_change_row.dart';
import '../components/match_detail/match_stats_tabs.dart';
import '../model/player.dart';
import '../model/scrimmage_match.dart';
import '../providers/elo_providers.dart';
import '../theme/app_colors.dart';

double teamInitialRating(ScrimmageMatch match, List<Player> players) {
  if (players.isEmpty) return 0;
  final total = players
      .map((player) => match.initialRatings[player.id] ?? player.rating)
      .reduce((a, b) => a + b);
  return total / players.length;
}

double expectedScore(double ratingA, double ratingB) {
  return 1 / (1 + pow(10, (ratingB - ratingA) / 400));
}

String dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, size: 18, color: AppColors.violet),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MatchScoreHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _MatchScoreHeaderDelegate({required this.match});

  final ScrimmageMatch match;

  static const _minBase = 132.0;
  static const _maxBase = 292.0;

  @override
  double get minExtent => _minBase + 0;

  @override
  double get maxExtent => _maxBase;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final progress = (shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);
    final safeTop = MediaQuery.paddingOf(context).top;
    final compact = progress > 0.52;
    final showExpanded = progress < 0.82;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sportHeaderDark.withValues(
          alpha: 0.84 + (0.14 * progress),
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.white.withValues(alpha: 0.08 + 0.08 * progress),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, safeTop + 8, 16, 12),
        child: Column(
          children: [
            Row(
              children: [
                HeaderIconButton(
                  size: 44 - (6 * progress),
                  icon: FIcons.chevronLeft,
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRoutes.matches);
                    }
                  },
                ),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: compact ? 1 : 0,
                    child: _CompactMatchTitle(match: match),
                  ),
                ),
                HeaderIconButton(
                  size: 44 - (6 * progress),
                  icon: FIcons.star,
                  onTap: () {},
                ),
              ],
            ),
            if (showExpanded)
              Expanded(
                child: ClipRect(
                  child: Opacity(
                    opacity: (1 - (progress / 0.82)).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -10 * progress),
                      child: Center(
                        child: Hero(
                          tag: matchHeroTag(match.id),
                          child: MatchScoreHeroPanel(
                            match: match,
                            framed: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MatchScoreHeaderDelegate oldDelegate) {
    return match != oldDelegate.match;
  }
}

class _CompactMatchTitle extends StatelessWidget {
  const _CompactMatchTitle({required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 7,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Transform.scale(
                scale: 0.54,
                child: TeamLogo(
                  name: match.teamAName,
                  highlighted: !match.isDraw && match.teamAWon,
                ),
              ),
              Flexible(
                child: Text(
                  match.teamAName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
        Text(
          '${match.scoreA} - ${match.scoreB}',
          style: textTheme.titleSmall?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Flexible(
                child: Text(
                  match.teamBName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.54,
                child: TeamLogo(
                  name: match.teamBName,
                  highlighted: !match.isDraw && !match.teamAWon,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GoalTimelineCard extends StatelessWidget {
  const GoalTimelineCard({super.key, required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context) {
    final goals = match.statEvents
        .where(
          (event) =>
              event.type == MatchStatType.goal ||
              event.type == MatchStatType.opponentGoal,
        )
        .toList();
    if (goals.isEmpty) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(FIcons.flag, color: AppColors.violet, size: 18),
                Text(
                  'Timeline mete',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            for (final (index, goal) in goals.indexed)
              _GoalTimelineRow(
                goal: goal,
                match: match,
                isLast: index == goals.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalTimelineRow extends StatelessWidget {
  const _GoalTimelineRow({
    required this.goal,
    required this.match,
    required this.isLast,
  });

  final MatchStatEvent goal;
  final ScrimmageMatch match;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isOurGoal = goal.type == MatchStatType.goal;
    final teamName = isOurGoal ? match.teamAName : match.teamBName;
    final minute = goal.createdAt.difference(match.createdAt).inMinutes;
    final description = goal.description?.trim().isNotEmpty == true
        ? goal.description!
        : '${goal.type.label} $teamName';
    final accent = isOurGoal ? AppColors.violet : AppColors.white;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isOurGoal ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accent.withValues(alpha: 0.34)),
                ),
                child: Icon(
                  isOurGoal ? FIcons.flag : FIcons.circleDot,
                  color: accent,
                  size: 17,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    color: AppColors.white.withValues(alpha: 0.10),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                spacing: 3,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${goal.scoreA} - ${goal.scoreB}',
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${minute <= 0 ? 1 : minute}’ · $teamName',
                    style: textTheme.bodySmall?.copyWith(
                      color: sportMutedText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hiveChangesProvider);
    final players = ref.watch(rankedPlayersProvider);
    final currentMatch = ref.watch(matchDetailsProvider(matchId));
    if (currentMatch == null) {
      return const Scaffold(
        body: SportScreenShell(
          title: 'Match',
          subtitle: 'Details not found',
          child: SportEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Partita non trovata',
            message: 'La partita selezionata non e piu disponibile.',
          ),
        ),
      );
    }

    final playersById = {for (final player in players) player.id: player};
    final teamA = currentMatch.teamAIds
        .map((id) => playersById[id])
        .nonNulls
        .toList();
    final teamB = currentMatch.teamBIds
        .map((id) => playersById[id])
        .nonNulls
        .toList();
    final preMatchRatingA = teamInitialRating(currentMatch, teamA);
    final preMatchRatingB = teamInitialRating(currentMatch, teamB);
    final winProbabilityA = expectedScore(preMatchRatingA, preMatchRatingB);
    final winProbabilityB = 1 - winProbabilityA;

    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: AppColors.transparent,
          systemNavigationBarColor: AppColors.sportBackgroundEnd,
          systemNavigationBarDividerColor: AppColors.transparent,
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topRight,
              radius: 1.25,
              colors: [
                AppColors.sportBackgroundStart,
                AppColors.sportBackgroundMid,
                AppColors.sportBackgroundEnd,
              ],
              stops: [0, 0.46, 1],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _MatchScoreHeaderDelegate(match: currentMatch),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    spacing: 12,
                    children: [
                      if (currentMatch.statEvents.length > 1) ...[
                        MatchStatsTabs(
                          match: currentMatch,
                          playersById: playersById,
                        ),
                        GoalTimelineCard(match: currentMatch),
                        ScoreTrendChart(match: currentMatch),
                      ] else ...[
                        TeamBlock(
                          title: currentMatch.teamAName,
                          players: teamA,
                          won: !currentMatch.isDraw && currentMatch.teamAWon,
                        ),
                        TeamBlock(
                          title: currentMatch.teamBName,
                          players: teamB,
                          won: !currentMatch.isDraw && !currentMatch.teamAWon,
                        ),
                        if (!currentMatch.isExternalOpponent) ...[
                          const SizedBox(height: 6),
                          const SectionTitle(
                            icon: FIcons.scale,
                            title: 'Pre-match',
                          ),
                          PreMatchBlock(
                            ratingA: preMatchRatingA,
                            ratingB: preMatchRatingB,
                            delta: preMatchRatingA - preMatchRatingB,
                            probabilityA: winProbabilityA,
                            probabilityB: winProbabilityB,
                            teamAName: currentMatch.teamAName,
                            teamBName: currentMatch.teamBName,
                          ),
                        ],
                      ],
                      if (!currentMatch.isExternalOpponent) ...[
                        const SizedBox(height: 6),
                        const SectionTitle(
                          icon: FIcons.trendingUpDown,
                          title: 'Variazioni ELO',
                        ),
                        ...[...teamA, ...teamB].map((player) {
                          return RatingChangeRow(
                            player: player,
                            initial: currentMatch.initialRatings[player.id],
                            finalRating: currentMatch.finalRatings[player.id],
                            delta: currentMatch.ratingDelta(player.id),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
