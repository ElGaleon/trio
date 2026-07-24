import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/features/auth/application/rbac_provider.dart';
import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:trio/src/features/players/presentation/players/player_card.dart';
import 'package:trio/src/features/players/presentation/players/player_filters.dart';
import 'package:trio/src/features/players/presentation/players/player_toolbar.dart';
import 'package:trio/src/shared/app_empty_state.dart';
import 'package:trio/src/shared/responsive_layout.dart';
import 'package:trio/src/shared/sport_button.dart';
import 'package:trio/src/shared/sport_screen_shell.dart';
import 'package:trio/src/features/players/application/player_providers.dart';
import 'package:trio/src/features/players/domain/player.dart';
import 'package:trio/theme/app_colors.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(playersSearchQueryProvider),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(firestoreTrioRepositoryProvider);
    final players = ref.watch(rankedPlayersProvider);
    final filteredPlayers = ref.watch(filteredPlayersProvider);
    final roleFilter = ref.watch(playersRoleFilterProvider);
    final lineFilter = ref.watch(playersLineFilterProvider);
    final role = ref.watch(currentRoleProvider);
    final canCreate = can(role, AppPermission.createPlayer);
    final canEdit = can(role, AppPermission.editPlayer);
    final canDelete = can(role, AppPermission.deletePlayer);
    final hasFilters =
        _searchController.text.isNotEmpty ||
        roleFilter != null ||
        lineFilter != null;

    return SportScreenShell(
      title: 'Players',
      subtitle: 'Roster and roles',
      floatingActionButton: canCreate
          ? SportFloatingActionButton(
              label: 'Nuovo',
              onPressed: () => context.go(AppRoutes.newPlayer),
            )
          : null,
      child: players.isEmpty
          ? Center(
              child: const SportEmptyState(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Nessun giocatore',
                message: 'Crea il roster della squadra.',
              ),
            )
          : Column(
              spacing: 12,
              children: [
                PlayerToolbar(
                  totalCount: players.length,
                  filteredCount: filteredPlayers.length,
                  hasFilters: hasFilters,
                ),
                PlayerFilters(
                  searchController: _searchController,
                  roleFilter: roleFilter,
                  lineFilter: lineFilter,
                  onSearchChanged: (value) =>
                      ref.read(playersSearchQueryProvider.notifier).set(value),
                  onRoleChanged: (value) =>
                      ref.read(playersRoleFilterProvider.notifier).set(value),
                  onLineChanged: (value) =>
                      ref.read(playersLineFilterProvider.notifier).set(value),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: 2,
                  ), // Adjust gap to match original 14 (12 spacing + 2 padding)
                  child: filteredPlayers.isEmpty
                      ? const SportEmptyState(
                          icon: Icons.manage_search_outlined,
                          title: 'Nessun risultato',
                          message: 'Prova a modificare i filtri.',
                        )
                      : ResponsiveLayout.isDesktop(context)
                      ? _PlayersTable(
                          players: filteredPlayers,
                          onOpen: (player) =>
                              context.go(AppRoutes.playerDetail(player.id)),
                          onEdit: canEdit
                              ? (player) => context.go(
                                  AppRoutes.editPlayer(player.id),
                                  extra: player,
                                )
                              : null,
                          onDelete: canDelete
                              ? (player) => repository?.deletePlayer(player.id)
                              : null,
                        )
                      : _PlayersCardPager(
                          players: filteredPlayers,
                          onOpen: (player) =>
                              context.go(AppRoutes.playerDetail(player.id)),
                          onEdit: canEdit
                              ? (player) => context.go(
                                  AppRoutes.editPlayer(player.id),
                                  extra: player,
                                )
                              : null,
                          onDelete: canDelete
                              ? (player) => repository?.deletePlayer(player.id)
                              : null,
                        ),
                ),
              ],
            ),
    );
  }
}

class _PlayersTable extends StatefulWidget {
  const _PlayersTable({
    required this.players,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Player> players;
  final ValueChanged<Player> onOpen;
  final ValueChanged<Player>? onEdit;
  final ValueChanged<Player>? onDelete;

  @override
  State<_PlayersTable> createState() => _PlayersTableState();
}

class _PlayersTableState extends State<_PlayersTable> {
  var _sortColumnIndex = 0;
  var _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    final rows = [...widget.players];
    rows.sort((a, b) {
      final result = switch (_sortColumnIndex) {
        1 => a.role.label.compareTo(b.role.label),
        2 => (a.linePreference?.label ?? '').compareTo(
          b.linePreference?.label ?? '',
        ),
        3 => (a.jerseyNumber ?? 9999).compareTo(b.jerseyNumber ?? 9999),
        4 => a.rating.compareTo(b.rating),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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
          _column('Nome', 0),
          _column('Ruolo', 1),
          _column('Linea', 2),
          _column('#', 3),
          _column('ELO', 4),
          const DataColumn(label: Text('Azioni')),
        ],
        rows: [
          for (final player in rows)
            DataRow(
              cells: [
                DataCell(Text(player.name), onTap: () => widget.onOpen(player)),
                DataCell(Text(player.role.label)),
                DataCell(Text(player.linePreference?.label ?? '-')),
                DataCell(Text(player.jerseyNumber?.toString() ?? '-')),
                DataCell(Text(player.rating.round().toString())),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Apri',
                        icon: Icon(Icons.open_in_new, size: 18),
                        onPressed: () => widget.onOpen(player),
                      ),
                      if (widget.onEdit != null)
                        IconButton(
                          tooltip: 'Modifica',
                          icon: Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => widget.onEdit!(player),
                        ),
                      if (widget.onDelete != null)
                        IconButton(
                          tooltip: 'Elimina',
                          icon: Icon(Icons.delete_outline, size: 18),
                          onPressed: () => widget.onDelete!(player),
                        ),
                    ],
                  ),
                ),
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

class _PlayersCardPager extends StatefulWidget {
  const _PlayersCardPager({
    required this.players,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final List<Player> players;
  final ValueChanged<Player> onOpen;
  final ValueChanged<Player>? onEdit;
  final ValueChanged<Player>? onDelete;

  @override
  State<_PlayersCardPager> createState() => _PlayersCardPagerState();
}

class _PlayersCardPagerState extends State<_PlayersCardPager> {
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
      spacing: 10,
      children: [
        for (final player in visible)
          PlayerCard(
            player: player,
            onTap: () => widget.onOpen(player),
            onEdit: widget.onEdit == null ? null : () => widget.onEdit!(player),
            onDelete: widget.onDelete == null
                ? null
                : () => widget.onDelete!(player),
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
