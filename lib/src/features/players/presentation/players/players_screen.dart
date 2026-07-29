import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:skrim/src/components/ui/infinite_scroll_list.dart';
import 'package:skrim/src/components/ui/paginated_table.dart';
import 'package:skrim/src/features/auth/application/rbac_provider.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/src/features/firebase/application/firebase_repository_provider.dart';
import 'package:skrim/src/features/players/presentation/players/player_card.dart';
import 'package:skrim/src/features/players/presentation/players/player_filters.dart';
import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/responsive_layout.dart';
import 'package:skrim/src/shared/sport_button.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';
import 'package:skrim/src/features/players/domain/player.dart';

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
    final repository = ref.watch(firestoreSkrimRepositoryProvider);
    final players = ref.watch(playersProvider);
    final filteredPlayers = ref.watch(filteredPlayersProvider);
    final roleFilter = ref.watch(playersRoleFilterProvider);
    final lineFilter = ref.watch(playersLineFilterProvider);
    final role = ref.watch(currentRoleProvider);
    final canCreate = can(role, AppPermission.createPlayer);
    final canEdit = can(role, AppPermission.editPlayer);
    final canDelete = can(role, AppPermission.deletePlayer);
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
              spacing: 16,
              children: [
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
                filteredPlayers.isEmpty
                    ? const SportEmptyState(
                        icon: Icons.manage_search_outlined,
                        title: 'Nessun risultato',
                        message: 'Prova a modificare i filtri.',
                      )
                    : ResponsiveLayout.isMobile(context)
                    ? _PlayersInfiniteList(
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
                    : _PlayersTable(
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

    return PaginatedTable<Player>(
      rows: rows,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      columns: [
        _column('#', 0),
        _column('Nome', 1),
        _column('Ruolo', 2),
        _column('Linea', 3),
        _column('ELO', 4),
        const DataColumn(label: Text('Azioni')),
      ],
      rowBuilder: (player) => DataRow(
        cells: [
          DataCell(Text(player.jerseyNumber?.toString() ?? '-')),
          DataCell(Text(player.name), onTap: () => widget.onOpen(player)),
          DataCell(Text(player.role.label)),
          DataCell(Text(player.linePreference?.label ?? '-')),
          DataCell(Text(player.rating.round().toString())),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Apri',
                  icon: const Icon(Icons.open_in_new, size: 18),
                  onPressed: () => widget.onOpen(player),
                ),
                if (widget.onEdit != null)
                  IconButton(
                    tooltip: 'Modifica',
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => widget.onEdit!(player),
                  ),
                if (widget.onDelete != null)
                  IconButton(
                    tooltip: 'Elimina',
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => widget.onDelete!(player),
                  ),
              ],
            ),
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

class _PlayersInfiniteList extends StatelessWidget {
  const _PlayersInfiniteList({
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
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final listHeight = (viewportHeight * 0.72).clamp(360.0, 720.0);

    return SizedBox(
      height: listHeight,
      child: InfiniteScrollList<Player>(
        items: players,
        itemBuilder: (context, player, index) => PlayerCard(
          player: player,
          onTap: () => onOpen(player),
          onEdit: onEdit == null ? null : () => onEdit!(player),
          onDelete: onDelete == null ? null : () => onDelete!(player),
        ),
      ),
    );
  }
}
