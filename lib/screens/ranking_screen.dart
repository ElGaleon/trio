import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../app_constants.dart';
import '../app_router.dart';
import '../models/player.dart';
import '../providers/elo_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/app_empty_state.dart';
import '../widgets/sport_style.dart';

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
      context.push(AppRoutes.playerDetail(player.id));
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
              children: [
                _RankingSummary(
                  totalCount: players.length,
                  filteredCount: filteredPlayers.length,
                  hasFilters: hasFilters,
                ),
                const SizedBox(height: 12),
                _RankingFilters(
                  roleFilter: roleFilter,
                  lineFilter: lineFilter,
                  onRoleChanged: (value) =>
                      ref.read(rankingRoleFilterProvider.notifier).state =
                          value,
                  onLineChanged: (value) =>
                      ref.read(rankingLineFilterProvider.notifier).state =
                          value,
                ),
                const SizedBox(height: 14),
                if (filteredPlayers.isEmpty)
                  const SportEmptyState(
                    icon: FIcons.searchX,
                    title: 'Nessun risultato',
                    message: 'Non ci sono giocatori per i filtri selezionati.',
                  )
                else ...[
                  _LeaderboardShowcase(
                    players: filteredPlayers.take(3).toList(),
                    rankByPlayerId: rankByPlayerId,
                    allAtInitialRating: allAtInitialRating,
                    onPlayerTap: openPlayer,
                  ),
                  const SizedBox(height: 16),
                  _LineAverageSummary(players: players),
                  const SizedBox(height: 18),
                  ...filteredPlayers
                      .skip(3)
                      .map(
                        (player) => _LeaderboardRow(
                          player: player,
                          rank: rankByPlayerId[player.id],
                          allAtInitialRating: allAtInitialRating,
                          onTap: () => openPlayer(player),
                        ),
                      ),
                ],
              ],
            ),
    );
  }
}

class _RankingSummary extends StatelessWidget {
  const _RankingSummary({
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        hasFilters
            ? '$filteredCount di $totalCount giocatori'
            : '$totalCount giocatori',
        style: textTheme.bodySmall?.copyWith(
          color: sportMutedText,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LeaderboardShowcase extends StatelessWidget {
  const _LeaderboardShowcase({
    required this.players,
    required this.rankByPlayerId,
    required this.allAtInitialRating,
    required this.onPlayerTap,
  });

  final List<Player> players;
  final Map<String, int> rankByPlayerId;
  final bool allAtInitialRating;
  final ValueChanged<Player> onPlayerTap;

  @override
  Widget build(BuildContext context) {
    final ordered = switch (players.length) {
      >= 3 => [players[1], players[0], players[2]],
      _ => players,
    };
    return Container(
      decoration: sportGlassDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white.withValues(alpha: 0.16),
            AppColors.white.withValues(alpha: 0.045),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 8,
            top: -24,
            child: Text(
              '#1',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.white.withValues(alpha: 0.055),
                fontSize: 118,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final player in ordered)
                  Expanded(
                    child: _PodiumPlayer(
                      player: player,
                      rank: rankByPlayerId[player.id],
                      featured:
                          players.isNotEmpty && player.id == players.first.id,
                      allAtInitialRating: allAtInitialRating,
                      onTap: () => onPlayerTap(player),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumPlayer extends StatelessWidget {
  const _PodiumPlayer({
    required this.player,
    required this.rank,
    required this.featured,
    required this.allAtInitialRating,
    required this.onTap,
  });

  final Player player;
  final int? rank;
  final bool featured;
  final bool allAtInitialRating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final avatarSize = featured ? 92.0 : 70.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: EdgeInsets.only(top: featured ? 0 : 28),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                SportPlayerAvatar(
                  initials: player.initials,
                  imagePath: player.profileImagePath,
                  size: avatarSize,
                  featured: featured,
                ),
                Positioned(
                  top: -4,
                  left: -2,
                  child: _RankBadge(
                    rank: rank,
                    muted: allAtInitialRating,
                    compact: !featured,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _shortName(player.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            _RatingPill(rating: player.rating.round(), emphasized: featured),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({
    required this.player,
    required this.rank,
    required this.allAtInitialRating,
    required this.onTap,
  });

  final Player player;
  final int? rank;
  final bool allAtInitialRating;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: sportGlassDecoration(),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '${rank ?? '-'}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SportPlayerAvatar(
              initials: player.initials,
              imagePath: player.profileImagePath,
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (!allAtInitialRating && (rank ?? 99) <= 3) ...[
              Icon(FIcons.trophy, size: 16, color: _rankColor(rank)),
              const SizedBox(width: 8),
            ],
            _RatingPill(rating: player.rating.round()),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({
    required this.rank,
    required this.muted,
    required this.compact,
  });

  final int? rank;
  final bool muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 24.0 : 30.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: muted
            ? AppColors.white.withValues(alpha: 0.18)
            : _rankColor(rank),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.sportBadgeBorder, width: 2),
      ),
      child: Text(
        '${rank ?? '-'}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.rating, this.emphasized = false});

  final int rating;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.violet.withValues(alpha: 0.18)
            : AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            FIcons.sparkles,
            size: 13,
            color: emphasized ? AppColors.violet : sportMutedText,
          ),
          const SizedBox(width: 5),
          Text(
            '$rating',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
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
      child: Container(
        decoration: sportGlassDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: sportMutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value == null ? '-' : value!.round().toString(),
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w900,
                ),
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
    return SizedBox(
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
    );
  }
}

Color _rankColor(int? rank) {
  return switch (rank) {
    1 => AppColors.violet,
    2 => AppColors.violetMid,
    3 => AppColors.violetLight,
    _ => sportMutedText,
  };
}

String _shortName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return value;
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.isEmpty) return value;
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last.characters.first}.';
}
