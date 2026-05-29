import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:trio/providers/match_provider.dart';

import '../models/player.dart';
import '../models/scrimmage_match.dart';
import '../providers/elo_providers.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hiveChangesProvider);
    final players = ref.watch(rankedPlayersProvider);
    final currentMatch = ref.watch(matchDetailsProvider(matchId));
    if (currentMatch == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dettaglio partita')),
        body: const Center(child: Text('Partita non trovata.')),
      );
    }
    final playersById = {for (final player in players) player.id: player};
    final teamA = currentMatch.teamAIds
        .map((id) => playersById[id])
        .nonNulls
        .toList();
    final teamB = currentMatch.teamBIds
        .map((id) => playersById[id])
        .nonNulls
        .toList();
    final preMatchRatingA = _teamInitialRating(currentMatch, teamA);
    final preMatchRatingB = _teamInitialRating(currentMatch, teamB);
    final preMatchDelta = preMatchRatingA - preMatchRatingB;
    final winProbabilityA = _expectedScore(preMatchRatingA, preMatchRatingB);
    final winProbabilityB = 1 - winProbabilityA;
    final teamAName = currentMatch.teamAName;
    final teamBName = currentMatch.teamBName;

    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio partita')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ScoreHeader(match: currentMatch),
          const SizedBox(height: 16),
          _TeamBlock(
            title: teamAName,
            players: teamA,
            won: !currentMatch.isDraw && currentMatch.teamAWon,
          ),
          const SizedBox(height: 12),
          _TeamBlock(
            title: teamBName,
            players: teamB,
            won: !currentMatch.isDraw && !currentMatch.teamAWon,
          ),
          const SizedBox(height: 16),
          _PreMatchBlock(
            ratingA: preMatchRatingA,
            ratingB: preMatchRatingB,
            delta: preMatchDelta,
            probabilityA: winProbabilityA,
            probabilityB: winProbabilityB,
            teamAName: teamAName,
            teamBName: teamBName,
          ),
          const SizedBox(height: 16),
          const _SectionTitle(
            icon: FIcons.trendingUpDown,
            title: 'Variazioni ELO',
          ),
          const SizedBox(height: 10),
          FTileGroup(
            children: [
              ...[...teamA, ...teamB].map((player) {
                final initial = currentMatch.initialRatings[player.id];
                final finalRating = currentMatch.finalRatings[player.id];
                final delta = currentMatch.ratingDelta(player.id);
                return _RatingChangeTile(
                  player: player,
                  initial: initial,
                  finalRating: finalRating,
                  delta: delta,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

double _teamInitialRating(ScrimmageMatch match, List<Player> players) {
  if (players.isEmpty) return 0;
  final total = players
      .map((player) => match.initialRatings[player.id] ?? player.rating)
      .reduce((a, b) => a + b);
  return total / players.length;
}

double _expectedScore(double ratingA, double ratingB) {
  return 1 / (1 + pow(10, (ratingB - ratingA) / 400));
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = match.isDraw
        ? 'Pareggio'
        : (match.teamAWon ? match.teamAName : match.teamBName);
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          spacing: 18,
          children: [
            Row(
              children: [
                const Icon(FIcons.calendarDays, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dateLabel(match.createdAt),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FBadge(
                  variant: .secondary,
                  child: Text('${match.teamSize}vs${match.teamSize}'),
                ),
                if (match.offenseVsDefense) ...[
                  const SizedBox(width: 8),
                  FBadge(variant: .outline, child: const Text('O vs D')),
                ],
              ],
            ),
            Row(
              children: [
                _ScoreSide(
                  label: match.teamAName,
                  score: match.scoreA,
                  won: !match.isDraw && match.teamAWon,
                ),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Icon(
                      FIcons.trophy,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                ),
                _ScoreSide(
                  label: match.teamBName,
                  score: match.scoreB,
                  won: !match.isDraw && !match.teamAWon,
                ),
              ],
            ),
            FDivider(),
            Row(
              children: [
                Icon(FIcons.badgeCheck, color: colorScheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.isDraw ? 'Risultato' : 'Vincitrice',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FBadge(
                  variant: match.isDraw ? .outline : .secondary,
                  child: Text(result),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreSide extends StatelessWidget {
  const _ScoreSide({
    required this.label,
    required this.score,
    required this.won,
  });

  final String label;
  final int score;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: won
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: won ? colorScheme.primary : colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          spacing: 6,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: won ? colorScheme.primary : colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              score.toString(),
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          ],
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

class _TeamBlock extends StatelessWidget {
  const _TeamBlock({
    required this.title,
    required this.players,
    required this.won,
  });

  final String title;
  final List<Player> players;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FCard(
      title: Row(
        children: [
          Icon(FIcons.users, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
          if (won) FBadge(variant: .secondary, child: const Text('Win')),
        ],
      ),
      child: FTileGroup(
        divider: .indented,
        children: [
          ...players.map(
            (player) => FTile(
              prefix: _PlayerAvatar(player: player),
              title: Text(player.name),
              subtitle: Text(
                '${player.role.label} · ${player.linePreference.label}',
              ),
              details: Text(player.rating.round().toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerAvatar extends StatelessWidget {
  const _PlayerAvatar({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FAvatar.raw(
      size: 34,
      child: Text(
        player.name.characters.first.toUpperCase(),
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PreMatchBlock extends StatelessWidget {
  const _PreMatchBlock({
    required this.ratingA,
    required this.ratingB,
    required this.delta,
    required this.probabilityA,
    required this.probabilityB,
    required this.teamAName,
    required this.teamBName,
  });

  final double ratingA;
  final double ratingB;
  final double delta;
  final double probabilityA;
  final double probabilityB;
  final String teamAName;
  final String teamBName;

  @override
  Widget build(BuildContext context) {
    final sign = delta >= 0 ? '+' : '';
    final colorScheme = Theme.of(context).colorScheme;
    return FCard(
      title: Row(
        children: [
          Icon(FIcons.scale, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Pre-match'),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricCard(
                  icon: FIcons.users,
                  label: 'Rating $teamAName',
                  value: ratingA.round().toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricCard(
                  icon: FIcons.shield,
                  label: 'Rating $teamBName',
                  value: ratingB.round().toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _MetricTile(
            icon: FIcons.arrowLeftRight,
            label: 'Delta pre-match',
            value: '$sign${delta.round()}',
          ),
          const SizedBox(height: 8),
          _MetricTile(
            icon: FIcons.percent,
            label: 'Probabilita $teamAName',
            value: '${(probabilityA * 100).round()}%',
          ),
          const SizedBox(height: 8),
          _MetricTile(
            icon: FIcons.percent,
            label: 'Probabilita $teamBName',
            value: '${(probabilityB * 100).round()}%',
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }
}

class _RatingChangeTile extends StatelessWidget with FTileMixin {
  const _RatingChangeTile({
    required this.player,
    required this.initial,
    required this.finalRating,
    required this.delta,
  });

  final Player player;
  final double? initial;
  final double? finalRating;
  final double delta;

  @override
  Widget build(BuildContext context) {
    final color = _deltaColor(context, delta);
    final sign = delta > 0 ? '+' : '';
    return FTile(
      prefix: Icon(
        delta == 0
            ? FIcons.minus
            : delta > 0
            ? FIcons.trendingUp
            : FIcons.trendingDown,
        color: color,
      ),
      title: Text(player.name),
      subtitle: Text(
        '${initial?.round() ?? '-'} -> ${finalRating?.round() ?? '-'}',
      ),
      details: Text(
        '$sign${delta.round()}',
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

Color _deltaColor(BuildContext context, double delta) {
  final colorScheme = Theme.of(context).colorScheme;
  if (delta > 0) return colorScheme.primary;
  if (delta < 0) return colorScheme.error;
  return colorScheme.onSurfaceVariant;
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
