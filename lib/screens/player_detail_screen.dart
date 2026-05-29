import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../models/player.dart';
import '../models/scrimmage_match.dart';
import '../providers/elo_providers.dart';
import '../widgets/rating_trend_chart.dart';

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
      return Scaffold(
        appBar: AppBar(title: const Text('Giocatore')),
        body: const Center(child: Text('Giocatore non trovato.')),
      );
    }
    final currentPlayer = player;
    final matches = repository.matchesForPlayer(currentPlayer.id);
    final history = repository.ratingHistoryForPlayer(currentPlayer.id);
    final playersById = {
      for (final rankedPlayer in players) rankedPlayer.id: rankedPlayer,
    };

    return Scaffold(
      appBar: AppBar(title: Text(currentPlayer.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _PlayerHero(player: currentPlayer),
          const SizedBox(height: 16),
          Row(
            children: [
              _StatBox(
                icon: FIcons.calendarCheck,
                label: 'Partite',
                value: '${currentPlayer.matchesPlayed}',
              ),
              const SizedBox(width: 10),
              _StatBox(
                icon: FIcons.trophy,
                label: 'Vittorie',
                value: '${currentPlayer.wins}',
              ),
              const SizedBox(width: 10),
              _StatBox(
                icon: FIcons.percent,
                label: 'Win rate',
                value: '${(currentPlayer.winRate * 100).round()}%',
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionTitle(icon: FIcons.activity, title: 'Andamento ELO'),
          const SizedBox(height: 10),
          FCard.raw(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: RatingTrendChart(values: history),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(icon: FIcons.history, title: 'Partite giocate'),
          const SizedBox(height: 10),
          if (matches.isEmpty)
            const FCard.raw(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nessuna partita registrata per questo giocatore.'),
              ),
            )
          else
            FTileGroup(
              divider: .indented,
              children: [
                ...matches.map(
                  (match) => _PlayerMatchTile(
                    player: currentPlayer,
                    match: match,
                    playersById: playersById,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlayerHero extends StatelessWidget {
  const _PlayerHero({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Hero(
      tag: 'player-${player.id}',
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              FAvatar.raw(
                size: 64,
                child: Text(
                  player.name.characters.first.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      player.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: player.rating),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (context, rating, _) {
                            return FBadge(child: Text('${rating.round()} ELO'));
                          },
                        ),
                        FBadge(
                          variant: .secondary,
                          child: Text(player.role.label),
                        ),
                        FBadge(
                          variant: .outline,
                          child: Text(player.linePreference.label),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: FCard.raw(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerMatchTile extends StatelessWidget with FTileMixin {
  const _PlayerMatchTile({
    required this.player,
    required this.match,
    required this.playersById,
  });

  final Player player;
  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final isTeamA = match.teamAIds.contains(player.id);
    final resultLabel = match.isDraw
        ? 'Pareggio'
        : (isTeamA == match.teamAWon ? 'Vittoria' : 'Sconfitta');
    final delta = match.ratingDelta(player.id);
    final color = _deltaColor(context, delta);
    final sign = delta > 0 ? '+' : '';
    final teammates = (isTeamA ? match.teamAIds : match.teamBIds)
        .where((id) => id != player.id)
        .map((id) => playersById[id]?.name)
        .whereType<String>()
        .join(', ');
    final teamName = isTeamA ? match.teamAName : match.teamBName;

    return FTile(
      prefix: Icon(_resultIcon(match, isTeamA, delta), color: color),
      title: Text('$teamName · ${match.scoreA} - ${match.scoreB}'),
      subtitle: Text(
        '$resultLabel · ${teammates.isEmpty ? 'Nessun compagno' : teammates}',
      ),
      details: Text(
        '$sign${delta.round()}',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

IconData _resultIcon(ScrimmageMatch match, bool isTeamA, double delta) {
  if (match.isDraw || delta == 0) return FIcons.minus;
  return isTeamA == match.teamAWon ? FIcons.trendingUp : FIcons.trendingDown;
}

Color _deltaColor(BuildContext context, double delta) {
  final colorScheme = Theme.of(context).colorScheme;
  if (delta > 0) return colorScheme.primary;
  if (delta < 0) return colorScheme.error;
  return colorScheme.onSurfaceVariant;
}
