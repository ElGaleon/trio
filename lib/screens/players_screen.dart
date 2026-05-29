import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:trio/models/player.dart';
import 'package:trio/providers/elo_providers.dart';
import 'package:trio/repositories/elo_repository.dart';
import 'package:trio/widgets/empty_state.dart';
import 'package:trio/widgets/player_card.dart';
import 'package:trio/screens/player_detail_screen.dart';

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

    return FScaffold(
      child: players.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Nessun giocatore',
                message: 'Crea il roster della squadra.',
                action: FButton(
                  onPress: () => showPlayerDialog(context, repository),
                  child: const Text('Crea giocatore'),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _PlayerToolbar(
                    onAdd: () => showPlayerDialog(context, repository),
                    child: _PlayerFilters(
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
                  );
                }

                final player = filteredPlayers[index - 1];
                return PlayerCard(
                  player: player,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerDetailScreen(playerId: player.id),
                    ),
                  ),
                  onEdit: () =>
                      showPlayerDialog(context, repository, player: player),
                  onDelete: () => repository.deletePlayer(player.id),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: filteredPlayers.length + 1,
            ),
    );
  }
}

Future<void> showPlayerDialog(
  BuildContext context,
  EloRepository repository, {
  Player? player,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => PlayerDialog(repository: repository, player: player),
  );
}

class PlayerDialog extends StatefulWidget {
  const PlayerDialog({super.key, required this.repository, this.player});

  final EloRepository repository;
  final Player? player;

  @override
  State<PlayerDialog> createState() => _PlayerDialogState();
}

class _PlayerDialogState extends State<PlayerDialog> {
  late final TextEditingController _controller;
  late PlayerLinePreference _linePreference;
  late PlayerRole _role;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.player?.name ?? '');
    _linePreference =
        widget.player?.linePreference ?? PlayerLinePreference.offense;
    _role = widget.player?.role ?? PlayerRole.cutter;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FDialog.adaptive(
      title: Text(
        widget.player == null ? 'Nuovo giocatore' : 'Modifica giocatore',
      ),
      actions: [
        FButton(onPress: _save, child: const Text('Salva')),
        FButton(
          variant: .outline,
          onPress: () => Navigator.pop(context),
          child: const Text('Annulla'),
        ),
      ],
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FTextFormField(
            control: FTextFieldControl.managed(controller: _controller),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            hint: 'Nome',
          ),
          const SizedBox(height: 12),
          FSelect<PlayerLinePreference>(
            items: {
              for (final line in PlayerLinePreference.values) line.label: line,
            },
            hint: 'Linea preferita',
            control: FSelectControl.managed(
              initial: _linePreference,
              onChange: (value) {
                if (value != null) setState(() => _linePreference = value);
              },
            ),
          ),
          const SizedBox(height: 12),
          FSelect<PlayerRole>(
            items: {for (final role in PlayerRole.values) role.label: role},
            hint: 'Ruolo',
            control: FSelectControl.managed(
              initial: _role,
              onChange: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (widget.player == null) {
      await widget.repository.addPlayerWithLine(
        _controller.text,
        _linePreference,
        _role,
      );
    } else {
      await widget.repository.savePlayer(
        widget.player!,
        name: _controller.text,
        linePreference: _linePreference,
        role: _role,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}

class _PlayerToolbar extends StatelessWidget {
  const _PlayerToolbar({required this.onAdd, required this.child});

  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FCard(
      title: Row(
        spacing: 4,
        children: [
          const Icon(FIcons.users, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('Giocatori')),
          FButton(
            size: .sm,
            onPress: onAdd,
            prefix: const Icon(FIcons.userPlus, size: 16),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
      child: child,
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
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        spacing: 8,
        children: [
          FTextFormField(
            control: FTextFieldControl.managed(
              controller: searchController,
              onChange: (value) => onSearchChanged(value.text),
            ),
            prefixBuilder: (context, style, states) =>
                const Icon(FIcons.search, size: 16),
            hint: 'Cerca giocatore',
          ),
          Row(
            children: [
              Expanded(
                child: FSelect<String>(
                  key: ValueKey('players-role-$roleFilter'),
                  items: {
                    'Tutti': 'all',
                    for (final role in PlayerRole.values) role.label: role.name,
                  },
                  hint: 'Ruolo',
                  control: FSelectControl.managed(
                    initial: roleFilter?.name ?? 'all',
                    onChange: (value) => onRoleChanged(
                      value == 'all' || value == null
                          ? null
                          : PlayerRole.values.firstWhere(
                              (role) => role.name == value,
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FSelect<String>(
                  key: ValueKey('players-line-$lineFilter'),
                  items: {
                    'Tutte': 'all',
                    PlayerLinePreference.offense.label:
                        PlayerLinePreference.offense.name,
                    PlayerLinePreference.defense.label:
                        PlayerLinePreference.defense.name,
                  },
                  hint: 'Linea',
                  control: FSelectControl.managed(
                    initial: lineFilter?.name ?? 'all',
                    onChange: (value) => onLineChanged(
                      value == 'all' || value == null
                          ? null
                          : PlayerLinePreference.values.firstWhere(
                              (line) => line.name == value,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (searchController.text.isNotEmpty ||
              roleFilter != null ||
              lineFilter != null)
            FButton(
              variant: .outline,
              onPress: () {
                searchController.clear();
                onSearchChanged('');
                onRoleChanged(null);
                onLineChanged(null);
              },
              prefix: const Icon(FIcons.x, size: 16),
              child: const Text('Pulisci filtri'),
            ),
        ],
      ),
    );
  }
}
