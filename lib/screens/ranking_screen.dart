import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:trio/widgets/player_ranking_card.dart';

import '../models/player.dart';
import '../providers/elo_providers.dart';
import '../widgets/empty_state.dart';
import 'player_detail_screen.dart';

class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(rankedPlayersProvider);
    if (players.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'Nessun ranking',
        message: 'Aggiungi i compagni e registra la prima partitella.',
      );
    }

    final filteredPlayers = ref.watch(filteredRankingPlayersProvider);
    final roleFilter = ref.watch(rankingRoleFilterProvider);
    final lineFilter = ref.watch(rankingLineFilterProvider);
    final rankByPlayerId = _buildRankByPlayerId(players);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _LineAverageSummary(players: players),
              const SizedBox(height: 12),
              _RankingFilters(
                roleFilter: roleFilter,
                lineFilter: lineFilter,
                onRoleChanged: (value) =>
                    ref.read(rankingRoleFilterProvider.notifier).state = value,
                onLineChanged: (value) =>
                    ref.read(rankingLineFilterProvider.notifier).state = value,
              ),
            ],
          );
        }

        final player = filteredPlayers[index - 1];
        return PlayerRankingCard(
          player: player,
          rank: rankByPlayerId[player.id],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerDetailScreen(playerId: player.id),
            ),
          ),
        );
      },
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemCount: filteredPlayers.length + 1,
    );
  }
}

Map<String, int> _buildRankByPlayerId(List<Player> players) {
  final allAtInitialRating = players.every((player) => player.rating == 1000);
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

class _LineAverageSummary extends StatelessWidget {
  const _LineAverageSummary({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    final offenseAverage = _averageRating(
      players.where(
        (player) => player.linePreference == PlayerLinePreference.offense,
      ),
    );
    final defenseAverage = _averageRating(
      players.where(
        (player) => player.linePreference == PlayerLinePreference.defense,
      ),
    );

    return Row(
      children: [
        _AverageCard(label: 'Media attacco', value: offenseAverage),
        const SizedBox(width: 10),
        _AverageCard(label: 'Media difesa', value: defenseAverage),
      ],
    );
  }

  double? _averageRating(Iterable<Player> players) {
    if (players.isEmpty) return null;
    final total = players
        .map((player) => player.rating)
        .reduce((a, b) => a + b);
    return total / players.length;
  }
}

class _AverageCard extends StatelessWidget {
  const _AverageCard({required this.label, required this.value});

  final String label;
  final double? value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value == null ? '-' : value!.round().toString(),
                style: textTheme.titleLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankingFilters extends StatelessWidget {
  const _RankingFilters({
    required this.roleFilter,
    required this.lineFilter,
    required this.onRoleChanged,
    required this.onLineChanged,
  });

  final PlayerRole? roleFilter;
  final PlayerLinePreference? lineFilter;
  final ValueChanged<PlayerRole?> onRoleChanged;
  final ValueChanged<PlayerLinePreference?> onLineChanged;

  @override
  Widget build(BuildContext context) {
    return FCard(
      title: const Row(
        children: [
          Icon(FIcons.slidersHorizontal, size: 18),
          SizedBox(width: 8),
          Text('Filtri'),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: FSelect<String>(
                  key: ValueKey('ranking-role-$roleFilter'),
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
                  key: ValueKey('ranking-line-$lineFilter'),
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
          if (roleFilter != null || lineFilter != null) ...[
            const SizedBox(height: 10),
            FButton(
              variant: .outline,
              onPress: () {
                onRoleChanged(null);
                onLineChanged(null);
              },
              prefix: const Icon(FIcons.x, size: 16),
              child: const Text('Pulisci filtri'),
            ),
          ],
        ],
      ),
    );
  }
}
