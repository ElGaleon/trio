import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/src/routing/app_router.dart';
import 'package:trio/src/features/players/presentation/players/player_card.dart';
import 'package:trio/src/features/players/presentation/players/player_filters.dart';
import 'package:trio/src/features/players/presentation/players/player_toolbar.dart';
import 'package:trio/src/common_widgets/app_empty_state.dart';
import 'package:trio/src/common_widgets/sport_button.dart';
import 'package:trio/src/common_widgets/sport_screen_shell.dart';
import 'package:trio/src/features/players/application/player_providers.dart';

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
    final repository = ref.watch(eloRepositoryProvider);
    final players = ref.watch(rankedPlayersProvider);
    final filteredPlayers = ref.watch(filteredPlayersProvider);
    final roleFilter = ref.watch(playersRoleFilterProvider);
    final lineFilter = ref.watch(playersLineFilterProvider);
    final hasFilters =
        _searchController.text.isNotEmpty ||
        roleFilter != null ||
        lineFilter != null;

    return SportScreenShell(
      title: 'Players',
      subtitle: 'Roster and roles',
      floatingActionButton: SportFloatingActionButton(
        label: 'Nuovo',
        onPressed: () => context.go(AppRoutes.newPlayer),
      ),
      child: players.isEmpty
          ? const SportEmptyState(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Nessun giocatore',
              message: 'Crea il roster della squadra.',
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
                      ref.read(playersSearchQueryProvider.notifier).state = value,
                  onRoleChanged: (value) =>
                      ref.read(playersRoleFilterProvider.notifier).state = value,
                  onLineChanged: (value) =>
                      ref.read(playersLineFilterProvider.notifier).state = value,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2), // Adjust gap to match original 14 (12 spacing + 2 padding)
                  child: filteredPlayers.isEmpty
                      ? const SportEmptyState(
                          icon: Icons.manage_search_outlined,
                          title: 'Nessun risultato',
                          message: 'Prova a modificare i filtri.',
                        )
                      : Column(
                          spacing: 12,
                          children: filteredPlayers.map(
                            (player) => PlayerCard(
                              player: player,
                              onTap: () => context.go(AppRoutes.playerDetail(player.id)),
                              onEdit: () => context.go(
                                AppRoutes.editPlayer(player.id),
                                extra: player,
                              ),
                              onDelete: () => repository.deletePlayer(player.id),
                            ),
                          ).toList(),
                        ),
                ),
              ],
            ),
    );
  }
}
