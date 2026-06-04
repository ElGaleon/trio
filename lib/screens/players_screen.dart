import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:trio/app_router.dart';
import 'package:trio/models/player.dart';
import 'package:trio/providers/elo_providers.dart';
import 'package:trio/widgets/app_empty_state.dart';
import 'package:trio/widgets/player_card.dart';
import 'package:trio/widgets/sport_style.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(playersSearchQueryProvider);
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
        onPressed: () => context.push(AppRoutes.newPlayer),
      ),
      child: players.isEmpty
          ? SportEmptyState(
              icon: Icons.person_add_alt_1_outlined,
              title: 'Nessun giocatore',
              message: 'Crea il roster della squadra.',
            )
          : Column(
              children: [
                _PlayerToolbar(
                  totalCount: players.length,
                  filteredCount: filteredPlayers.length,
                  hasFilters: hasFilters,
                ),
                const SizedBox(height: 12),
                _PlayerFilters(
                  searchController: _searchController,
                  roleFilter: roleFilter,
                  lineFilter: lineFilter,
                  onSearchChanged: (value) =>
                      ref.read(playersSearchQueryProvider.notifier).state =
                          value,
                  onRoleChanged: (value) =>
                      ref.read(playersRoleFilterProvider.notifier).state =
                          value,
                  onLineChanged: (value) =>
                      ref.read(playersLineFilterProvider.notifier).state =
                          value,
                ),
                const SizedBox(height: 14),
                if (filteredPlayers.isEmpty)
                  const SportEmptyState(
                    icon: Icons.manage_search_outlined,
                    title: 'Nessun risultato',
                    message: 'Prova a modificare i filtri.',
                  )
                else
                  ...filteredPlayers.map(
                    (player) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PlayerCard(
                        player: player,
                        onTap: () =>
                            context.push(AppRoutes.playerDetail(player.id)),
                        onEdit: () => context.push(
                          AppRoutes.editPlayer(player.id),
                          extra: player,
                        ),
                        onDelete: () => repository.deletePlayer(player.id),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _PlayerToolbar extends StatelessWidget {
  const _PlayerToolbar({
    required this.totalCount,
    required this.filteredCount,
    required this.hasFilters,
  });

  final int totalCount;
  final int filteredCount;
  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            hasFilters
                ? '$filteredCount di $totalCount giocatori'
                : '$totalCount giocatori',
            style: textTheme.bodySmall?.copyWith(
              color: sportMutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerFilters extends StatelessWidget {
  const _PlayerFilters({
    required this.searchController,
    required this.roleFilter,
    required this.lineFilter,
    required this.onSearchChanged,
    required this.onRoleChanged,
    required this.onLineChanged,
  });

  final TextEditingController searchController;
  final PlayerRole? roleFilter;
  final PlayerLinePreference? lineFilter;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<PlayerRole?> onRoleChanged;
  final ValueChanged<PlayerLinePreference?> onLineChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        FTextFormField(
          control: FTextFieldControl.managed(
            controller: searchController,
            onChange: (value) => onSearchChanged(value.text),
          ),
          prefixBuilder: (context, style, states) => const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Icon(FIcons.search, size: 15),
          ),
          hint: 'Cerca giocatore',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            children: [
              SportFilterPill(
                label: 'Handler',
                selected: roleFilter == PlayerRole.handler,
                onPressed: () => onRoleChanged(
                  roleFilter == PlayerRole.handler ? null : PlayerRole.handler,
                ),
              ),
              const SizedBox(width: 8),
              SportFilterPill(
                label: 'Cutter',
                selected: roleFilter == PlayerRole.cutter,
                onPressed: () => onRoleChanged(
                  roleFilter == PlayerRole.cutter ? null : PlayerRole.cutter,
                ),
              ),
              const SizedBox(width: 8),
              SportFilterPill(
                label: 'Attacco',
                selected: lineFilter == PlayerLinePreference.offense,
                onPressed: () => onLineChanged(
                  lineFilter == PlayerLinePreference.offense
                      ? null
                      : PlayerLinePreference.offense,
                ),
              ),
              const SizedBox(width: 8),
              SportFilterPill(
                label: 'Difesa',
                selected: lineFilter == PlayerLinePreference.defense,
                onPressed: () => onLineChanged(
                  lineFilter == PlayerLinePreference.defense
                      ? null
                      : PlayerLinePreference.defense,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
