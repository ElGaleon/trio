import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/features/players/presentation/player_detail/player_detail_section_title.dart';
import 'package:trio/src/features/players/presentation/player_detail/player_hero.dart';
import 'package:trio/src/features/players/presentation/player_detail/player_match_row.dart';
import 'package:trio/src/features/players/presentation/player_detail/stat_box.dart';
import 'package:trio/src/features/players/presentation/ranking/rating_trend_chart.dart';
import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/sport_avatar_pill.dart';
import 'package:trio/src/shared/sport_button.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/matches/domain/scrimmage_match.dart';
import 'package:trio/src/features/players/application/player_providers.dart';
import 'package:trio/src/features/players/application/player_stats_provider.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/shared/sport_glass_decoration_helper.dart';
import 'package:trio/src/features/players/domain/player_stats_card_data.dart';

class PlayerDetailScreen extends ConsumerWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hiveChangesProvider);
    final repository = ref.watch(eloRepositoryProvider);
    final players = ref.watch(rankedPlayersProvider);
    Player? player;
    for (final rankedPlayer in players) {
      if (rankedPlayer.id == playerId) {
        player = rankedPlayer;
        break;
      }
    }

    if (player == null) {
      return const Scaffold(
        body: SportScreenShell(
          title: 'Player',
          subtitle: 'Profile not found',
          child: SportEmptyState(
            icon: Icons.person_off_outlined,
            title: 'Giocatore non trovato',
            message: 'Il profilo selezionato non e piu disponibile.',
          ),
        ),
      );
    }

    final currentPlayer = player;
    final matches = repository.matchesForPlayer(currentPlayer.id);
    final filteredStats = ref.watch(
      playerDetailStatsProvider(currentPlayer.id),
    );
    final tournamentFilter = ref.watch(
      playerDetailTournamentFilterProvider(currentPlayer.id),
    );
    final matchFilter = ref.watch(
      playerDetailMatchFilterProvider(currentPlayer.id),
    );
    final history = repository.ratingHistoryForPlayer(currentPlayer.id);
    final playersById = {
      for (final rankedPlayer in players) rankedPlayer.id: rankedPlayer,
    };

    return Scaffold(
      body: SportScreenShell(
        title: 'Player',
        subtitle: 'Performance profile',
        showBackButton: true,
        child: Column(
          spacing: 12,
          children: [
            PlayerHero(player: currentPlayer),
            Align(
              alignment: Alignment.centerLeft,
              child: SportActionButton(
                label: 'Modifica',
                icon: FIcons.pencil,
                onPressed: () => context.go(
                  AppRoutes.editPlayer(currentPlayer.id),
                  extra: currentPlayer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ), // 12 spacing + 2 padding = 14 total
              child: Row(
                spacing: 10,
                children: [
                  StatBox(
                    icon: FIcons.calendarCheck,
                    label: 'Partite',
                    value: '${currentPlayer.matchesPlayed}',
                  ),
                  StatBox(
                    icon: FIcons.trophy,
                    label: 'Vittorie',
                    value: '${currentPlayer.wins}',
                  ),
                  StatBox(
                    icon: FIcons.percent,
                    label: 'Win rate',
                    value: '${(currentPlayer.winRate * 100).round()}%',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ), // 12 spacing + 8 padding = 20 total
              child: const PlayerDetailSectionTitle(
                icon: FIcons.activity,
                title: 'Andamento ELO',
              ),
            ),
            GlassDecoration(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: RatingTrendChart(values: history),
              ),
            ),
            if (filteredStats != null) ...[
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: const PlayerDetailSectionTitle(
                  icon: FIcons.chartNoAxesCombined,
                  title: 'Statistiche',
                ),
              ),
              _PlayerStatsFilters(
                playerId: currentPlayer.id,
                matches: matches,
                tournaments: filteredStats.tournaments,
                selectedTournament: tournamentFilter,
                selectedMatchId: matchFilter,
              ),
              _PlayerStatsSummary(data: filteredStats.data),
            ],
            Padding(
              padding: const EdgeInsets.only(
                top: 8,
              ), // 12 spacing + 8 padding = 20 total
              child: const PlayerDetailSectionTitle(
                icon: FIcons.history,
                title: 'Partite giocate',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 2,
              ), // 12 spacing + 2 padding = 14 total (or 10)
              child: matches.isEmpty
                  ? const SportEmptyState(
                      icon: FIcons.history,
                      title: 'Nessuna partita',
                      message:
                          'Questo giocatore non ha ancora partite registrate.',
                    )
                  : Column(
                      children: matches
                          .map(
                            (match) => PlayerMatchRow(
                              player: currentPlayer,
                              match: match,
                              playersById: playersById,
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStatsFilters extends ConsumerWidget {
  const _PlayerStatsFilters({
    required this.playerId,
    required this.matches,
    required this.tournaments,
    required this.selectedTournament,
    required this.selectedMatchId,
  });

  final String playerId;
  final List<ScrimmageMatch> matches;
  final List<String> tournaments;
  final String? selectedTournament;
  final String? selectedMatchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleMatches = selectedTournament == null
        ? matches
        : matches
              .where((match) => match.tournament.trim() == selectedTournament)
              .toList();

    return Column(
      spacing: 8,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              SportFilterPill(
                label: 'Tutti tornei',
                selected: selectedTournament == null,
                onPressed: () {
                  ref
                          .read(
                            playerDetailTournamentFilterProvider(
                              playerId,
                            ).notifier,
                          )
                          .state =
                      null;
                  ref
                          .read(
                            playerDetailMatchFilterProvider(playerId).notifier,
                          )
                          .state =
                      null;
                },
              ),
              for (final tournament in tournaments)
                SportFilterPill(
                  label: tournament,
                  selected: selectedTournament == tournament,
                  onPressed: () {
                    ref
                            .read(
                              playerDetailTournamentFilterProvider(
                                playerId,
                              ).notifier,
                            )
                            .state =
                        tournament;
                    ref
                            .read(
                              playerDetailMatchFilterProvider(
                                playerId,
                              ).notifier,
                            )
                            .state =
                        null;
                  },
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              SportFilterPill(
                label: 'Tutte partite',
                selected: selectedMatchId == null,
                onPressed: () =>
                    ref
                            .read(
                              playerDetailMatchFilterProvider(
                                playerId,
                              ).notifier,
                            )
                            .state =
                        null,
              ),
              for (final match in visibleMatches)
                SportFilterPill(
                  label: _matchFilterLabel(match),
                  selected: selectedMatchId == match.id,
                  onPressed: () =>
                      ref
                          .read(
                            playerDetailMatchFilterProvider(playerId).notifier,
                          )
                          .state = match
                          .id,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlayerStatsSummary extends StatelessWidget {
  const _PlayerStatsSummary({required this.data});

  final PlayerStatsCardData data;

  @override
  Widget build(BuildContext context) {
    return GlassDecoration(
              child: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            _MiniStat(label: '+/-', value: _signed(data.plusMinus)),
            _MiniStat(label: 'Mete', value: '${data.goals}'),
            _MiniStat(label: 'Assist', value: '${data.assists}'),
            _MiniStat(label: 'Difese', value: '${data.defenses}'),
            _MiniStat(label: 'Errori', value: '${data.errors}'),
            _MiniStat(label: 'Pull dentro', value: _percent(data.pullInRate)),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: sportMutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}

String _matchFilterLabel(ScrimmageMatch match) {
  final tournament = match.tournament.trim();
  final prefix = tournament.isEmpty ? _dateLabel(match.createdAt) : tournament;
  return '$prefix · ${match.scoreA}-${match.scoreB}';
}

String _percent(double value) => '${(value * 100).round()}%';

String _signed(double value) {
  final rounded = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 1,
  );
  return value > 0 ? '+$rounded' : rounded;
}
