import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/features/auth/application/rbac_provider.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/sport_button.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/theme/app_colors.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/matches/application/match_provider.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/application/player_providers.dart';
import 'match_score_header_delegate.dart';
import 'goal_timeline_card.dart';
import 'match_detail_section_title.dart';
import 'team_block.dart';
import 'pre_match_block.dart';
import 'rating_change_row.dart';
import 'match_stats_tabs.dart';
import 'score_trend_chart.dart';

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

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final rosterA = currentMatch.teamARosterIds.isNotEmpty
        ? currentMatch.teamARosterIds
        : currentMatch.teamAIds;
    final rosterB = currentMatch.teamBRosterIds.isNotEmpty
        ? currentMatch.teamBRosterIds
        : currentMatch.teamBIds;
    final teamA = rosterA.map((id) => playersById[id]).nonNulls.toList();
    final teamB = rosterB.map((id) => playersById[id]).nonNulls.toList();
    final preMatchRatingA = teamInitialRating(currentMatch, teamA);
    final preMatchRatingB = teamInitialRating(currentMatch, teamB);
    final winProbabilityA = expectedScore(preMatchRatingA, preMatchRatingB);
    final winProbabilityB = 1 - winProbabilityA;
    final liveNow = currentMatch.isLiveAt(DateTime.now());
    final canOpenLive =
        can(ref.watch(currentRoleProvider), AppPermission.recordLiveStats) &&
        liveNow;

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
                delegate: MatchScoreHeaderDelegate(match: currentMatch),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    spacing: 12,
                    children: [
                      if (canOpenLive)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SportActionButton(
                            label: 'Apri live stats',
                            icon: FIcons.activity,
                            onPressed: () => context.go(
                              AppRoutes.liveStats(currentMatch.id),
                            ),
                          ),
                        ),
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
                          const MatchDetailSectionTitle(
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
                        const MatchDetailSectionTitle(
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
