import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/constants/app_constants.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/features/players/presentation/ranking/leaderboard_row.dart';
import 'package:trio/src/features/players/presentation/ranking/leaderboard_showcase.dart';
import 'package:trio/src/features/players/presentation/ranking/line_average_summary.dart';
import 'package:trio/src/features/players/presentation/ranking/ranking_filters.dart';
import 'package:trio/src/features/players/presentation/ranking/ranking_summary.dart';
import 'package:trio/src/common_widgets/app_empty_state.dart';
import 'package:trio/src/common_widgets/sport_screen_shell.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/application/player_providers.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(rankedPlayersProvider);
    final filteredPlayers = ref.watch(filteredRankingPlayersProvider);
    final roleFilter = ref.watch(rankingRoleFilterProvider);
    final lineFilter = ref.watch(rankingLineFilterProvider);
    final hasFilters = roleFilter != null || lineFilter != null;
    final rankByPlayerId = _buildRankByPlayerId(players);
    final allAtInitialRating = players.every(
      (player) => player.rating == AppConstants.initialRating,
    );

    void openPlayer(Player player) {
      context.go(AppRoutes.playerDetail(player.id));
    }

    return SportScreenShell(
      title: 'Ranking',
      subtitle: 'Best of the team',
      child: players.isEmpty
          ? const SportEmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'Nessun ranking',
              message: 'Aggiungi i compagni e registra la prima partitella.',
            )
          : Column(
              spacing: 8,
              children: [
                RankingSummary(
                  totalCount: players.length,
                  filteredCount: filteredPlayers.length,
                  hasFilters: hasFilters,
                ),
                RankingFilters(
                  roleFilter: roleFilter,
                  lineFilter: lineFilter,
                  onRoleChanged: (value) =>
                      ref.read(rankingRoleFilterProvider.notifier).state = value,
                  onLineChanged: (value) =>
                      ref.read(rankingLineFilterProvider.notifier).state = value,
                ),
                if (filteredPlayers.isEmpty)
                  const SportEmptyState(
                    icon: FIcons.searchX,
                    title: 'Nessun risultato',
                    message: 'Non ci sono giocatori per i filtri selezionati.',
                  )
                else ...[
                  LeaderboardShowcase(
                    players: filteredPlayers.take(3).toList(),
                    rankByPlayerId: rankByPlayerId,
                    allAtInitialRating: allAtInitialRating,
                    onPlayerTap: openPlayer,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8), // 8 spacing + 8 padding = 16 total
                    child: LineAverageSummary(players: players),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 10), // 8 spacing + 10 padding = 18 total
                    child: Column(
                      children: filteredPlayers
                          .skip(3)
                          .map(
                            (player) => LeaderboardRow(
                              player: player,
                              rank: rankByPlayerId[player.id],
                              allAtInitialRating: allAtInitialRating,
                              onTap: () => openPlayer(player),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Map<String, int> _buildRankByPlayerId(List<Player> players) {
    final allAtInitialRating = players.every(
      (player) => player.rating == AppConstants.initialRating,
    );
    if (allAtInitialRating) {
      return {for (final entry in players.indexed) entry.$2.id: entry.$1 + 1};
    }

    final ranks = <String, int>{};
    double? previousRating;
    var currentRank = 0;
    for (final entry in players.indexed) {
      final position = entry.$1 + 1;
      final player = entry.$2;
      if (previousRating == null || player.rating != previousRating) {
        currentRank = position;
        previousRating = player.rating;
      }
      ranks[player.id] = currentRank;
    }
    return ranks;
  }
}
