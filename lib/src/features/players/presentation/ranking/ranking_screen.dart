import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/constants/app_constants.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/features/players/presentation/ranking/leaderboard_row.dart';
import 'package:trio/src/features/players/presentation/ranking/line_average_summary.dart';
import 'package:trio/src/features/players/presentation/ranking/ranking_filters.dart';
import 'package:trio/src/features/players/presentation/ranking/ranking_summary.dart';
import 'package:trio/src/features/matches/presentation/matches/match_date_filters.dart';
import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/responsive_layout.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/src/features/players/application/player_providers.dart';
import 'package:trio/theme/app_colors.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(rankedPlayersProvider);
    final filteredPlayers = ref.watch(filteredRankingPlayersProvider);
    final roleFilter = ref.watch(rankingRoleFilterProvider);
    final lineFilter = ref.watch(rankingLineFilterProvider);
    final startDate = ref.watch(rankingStartDateFilterProvider);
    final endDate = ref.watch(rankingEndDateFilterProvider);
    final hasFilters =
        roleFilter != null ||
        lineFilter != null ||
        startDate != null ||
        endDate != null;
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
              mainAxisAlignment: MainAxisAlignment.start,
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
                      ref.read(rankingRoleFilterProvider.notifier).set(value),
                  onLineChanged: (value) =>
                      ref.read(rankingLineFilterProvider.notifier).set(value),
                ),
                MatchDateFilters(
                  startDate: startDate,
                  endDate: endDate,
                  onStartChanged: (value) => ref
                      .read(rankingStartDateFilterProvider.notifier)
                      .set(value),
                  onEndChanged: (value) => ref
                      .read(rankingEndDateFilterProvider.notifier)
                      .set(value),
                ),
                if (filteredPlayers.isEmpty)
                  const SportEmptyState(
                    icon: FIcons.searchX,
                    title: 'Nessun risultato',
                    message: 'Non ci sono giocatori per i filtri selezionati.',
                  )
                else if (ResponsiveLayout.isDesktop(context)) ...[
                  LineAverageSummary(players: players),
                  _RankingTable(
                    players: filteredPlayers,
                    rankByPlayerId: rankByPlayerId,
                    onOpen: openPlayer,
                  ),
                ] else
                  _RankingCardPager(
                    players: filteredPlayers,
                    rankByPlayerId: rankByPlayerId,
                    allAtInitialRating: allAtInitialRating,
                    onOpen: openPlayer,
                  ),
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

class _RankingTable extends StatefulWidget {
  const _RankingTable({
    required this.players,
    required this.rankByPlayerId,
    required this.onOpen,
  });

  final List<Player> players;
  final Map<String, int> rankByPlayerId;
  final ValueChanged<Player> onOpen;

  @override
  State<_RankingTable> createState() => _RankingTableState();
}

class _RankingTableState extends State<_RankingTable> {
  var _sortColumnIndex = 0;
  var _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final rows = [...widget.players];
    rows.sort((a, b) {
      final result = switch (_sortColumnIndex) {
        1 => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        2 => a.rating.compareTo(b.rating),
        3 => a.role.label.compareTo(b.role.label),
        4 => (a.linePreference?.label ?? '').compareTo(
          b.linePreference?.label ?? '',
        ),
        5 => a.winRate.compareTo(b.winRate),
        _ => (widget.rankByPlayerId[a.id] ?? 9999).compareTo(
          widget.rankByPlayerId[b.id] ?? 9999,
        ),
      };
      return _sortAscending ? result : -result;
    });

    return _TableShell(
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        headingRowHeight: 38,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 48,
        columns: [
          _column('#', 0),
          _column('Nome', 1),
          _column('ELO', 2),
          _column('Ruolo', 3),
          _column('Linea', 4),
          _column('Win rate', 5),
        ],
        rows: [
          for (final player in rows)
            DataRow(
              cells: [
                DataCell(Text('${widget.rankByPlayerId[player.id] ?? '-'}')),
                DataCell(Text(player.name), onTap: () => widget.onOpen(player)),
                DataCell(Text(player.rating.round().toString())),
                DataCell(Text(player.role.label)),
                DataCell(Text(player.linePreference?.label ?? '-')),
                DataCell(Text('${(player.winRate * 100).round()}%')),
              ],
            ),
        ],
      ),
    );
  }

  DataColumn _column(String label, int index) {
    return DataColumn(
      label: Text(label),
      onSort: (columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
      },
    );
  }
}

class _RankingCardPager extends StatefulWidget {
  const _RankingCardPager({
    required this.players,
    required this.rankByPlayerId,
    required this.allAtInitialRating,
    required this.onOpen,
  });

  final List<Player> players;
  final Map<String, int> rankByPlayerId;
  final bool allAtInitialRating;
  final ValueChanged<Player> onOpen;

  @override
  State<_RankingCardPager> createState() => _RankingCardPagerState();
}

class _RankingCardPagerState extends State<_RankingCardPager> {
  static const _pageSize = 8;
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final maxPage = ((widget.players.length - 1) / _pageSize).floor().clamp(
      0,
      999,
    );
    if (_page > maxPage) _page = maxPage;
    final visible = widget.players.skip(_page * _pageSize).take(_pageSize);

    return Column(
      children: [
        for (final player in visible)
          LeaderboardRow(
            player: player,
            rank: widget.rankByPlayerId[player.id],
            allAtInitialRating: widget.allAtInitialRating,
            onTap: () => widget.onOpen(player),
          ),
        _PagerControls(
          page: _page,
          maxPage: maxPage,
          onPrevious: _page == 0 ? null : () => setState(() => _page--),
          onNext: _page == maxPage ? null : () => setState(() => _page++),
        ),
      ],
    );
  }
}

class _TableShell extends StatelessWidget {
  const _TableShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sportForeground(context).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.sportForeground(context).withValues(alpha: 0.10),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}

class _PagerControls extends StatelessWidget {
  const _PagerControls({
    required this.page,
    required this.maxPage,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int maxPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          IconButton(onPressed: onPrevious, icon: Icon(Icons.chevron_left)),
          Text(
            '${page + 1}/${maxPage + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.sportMutedForeground(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(onPressed: onNext, icon: Icon(Icons.chevron_right)),
        ],
      ),
    );
  }
}
