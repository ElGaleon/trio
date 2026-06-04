import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:trio/providers/match_provider.dart';
import 'package:trio/widgets/app_empty_state.dart';

import '../models/player.dart';
import '../models/scrimmage_match.dart';
import '../providers/elo_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/sport_style.dart';

class MatchDetailScreen extends ConsumerWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(hiveChangesProvider);
    final players = ref.watch(rankedPlayersProvider);
    final currentMatch = ref.watch(matchDetailsProvider(matchId));
    if (currentMatch == null) {
      return const Scaffold(
        body: SportScreenShell(
          title: 'Match',
          subtitle: 'Details not found',
          child: SportEmptyState(
            icon: Icons.event_busy_outlined,
            title: 'Partita non trovata',
            message: 'La partita selezionata non e piu disponibile.',
          ),
        ),
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
    final winProbabilityA = _expectedScore(preMatchRatingA, preMatchRatingB);
    final winProbabilityB = 1 - winProbabilityA;

    return Scaffold(
      body: SportScreenShell(
        title: 'Match',
        subtitle: _dateLabel(currentMatch.createdAt),
        child: Column(
          children: [
            const SportBackButton(),
            const SizedBox(height: 14),
            _ScoreHero(match: currentMatch),
            const SizedBox(height: 16),
            _TeamBlock(
              title: currentMatch.teamAName,
              players: teamA,
              won: !currentMatch.isDraw && currentMatch.teamAWon,
            ),
            const SizedBox(height: 12),
            _TeamBlock(
              title: currentMatch.teamBName,
              players: teamB,
              won: !currentMatch.isDraw && !currentMatch.teamAWon,
            ),
            const SizedBox(height: 18),
            _SectionTitle(icon: FIcons.scale, title: 'Pre-match'),
            const SizedBox(height: 10),
            _PreMatchBlock(
              ratingA: preMatchRatingA,
              ratingB: preMatchRatingB,
              delta: preMatchRatingA - preMatchRatingB,
              probabilityA: winProbabilityA,
              probabilityB: winProbabilityB,
              teamAName: currentMatch.teamAName,
              teamBName: currentMatch.teamBName,
            ),
            const SizedBox(height: 18),
            const _SectionTitle(
              icon: FIcons.trendingUpDown,
              title: 'Variazioni ELO',
            ),
            const SizedBox(height: 10),
            ...[...teamA, ...teamB].map((player) {
              return _RatingChangeRow(
                player: player,
                initial: currentMatch.initialRatings[player.id],
                finalRating: currentMatch.finalRatings[player.id],
                delta: currentMatch.ratingDelta(player.id),
              );
            }),
          ],
        ),
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

class _ScoreHero extends StatelessWidget {
  const _ScoreHero({required this.match});

  final ScrimmageMatch match;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final result = match.isDraw
        ? 'Pareggio'
        : (match.teamAWon ? match.teamAName : match.teamBName);
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
            top: -22,
            child: Text(
              '${match.scoreA}-${match.scoreB}',
              style: textTheme.displayLarge?.copyWith(
                color: AppColors.white.withValues(alpha: 0.045),
                fontSize: 92,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      match.offenseVsDefense ? FIcons.shield : FIcons.users,
                      color: AppColors.violet,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        match.offenseVsDefense
                            ? 'Attacco vs difesa'
                            : 'Squadre libere',
                        style: textTheme.bodySmall?.copyWith(
                          color: sportMutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    _InfoPill(label: '${match.teamSize}vs${match.teamSize}'),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _ScoreSide(
                      label: match.teamAName,
                      score: match.scoreA,
                      won: !match.isDraw && match.teamAWon,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        match.isDraw ? FIcons.minus : FIcons.trophy,
                        color: AppColors.violet,
                        size: 28,
                      ),
                    ),
                    _ScoreSide(
                      label: match.teamBName,
                      score: match.scoreB,
                      won: !match.isDraw && !match.teamAWon,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      match.isDraw ? 'Risultato' : 'Vincitrice',
                      style: textTheme.bodySmall?.copyWith(
                        color: sportMutedText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    _InfoPill(label: result, emphasized: !match.isDraw),
                  ],
                ),
              ],
            ),
          ),
        ],
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
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: won
              ? AppColors.violet.withValues(alpha: 0.18)
              : AppColors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: won
                ? AppColors.violet
                : AppColors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.labelMedium?.copyWith(
                color: won ? AppColors.white : sportMutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              score.toString(),
              style: textTheme.displaySmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
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
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: sportGlassDecoration(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      child: Column(
        children: [
          Row(
            children: [
              Icon(FIcons.users, size: 18, color: AppColors.violet),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (won) const _InfoPill(label: 'Win', emphasized: true),
            ],
          ),
          const SizedBox(height: 10),
          ...players.map(
            (player) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SportPlayerAvatar(
                    initials: player.initials,
                    imagePath: player.profileImagePath,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          [
                            player.role.label,
                            player.linePreference.label,
                            if (player.isExternal) 'Esterno',
                          ].join(' · '),
                          style: textTheme.bodySmall?.copyWith(
                            color: sportMutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _InfoPill(label: player.rating.round().toString()),
                ],
              ),
            ),
          ),
        ],
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
    return Column(
      children: [
        Row(
          children: [
            _MetricCard(label: teamAName, value: ratingA.round().toString()),
            const SizedBox(width: 10),
            _MetricCard(label: teamBName, value: ratingB.round().toString()),
          ],
        ),
        const SizedBox(height: 10),
        _MetricRow(label: 'Delta pre-match', value: '$sign${delta.round()}'),
        _MetricRow(
          label: 'Probabilita $teamAName',
          value: '${(probabilityA * 100).round()}%',
        ),
        _MetricRow(
          label: 'Probabilita $teamBName',
          value: '${(probabilityB * 100).round()}%',
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        decoration: sportGlassDecoration(radius: 22),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(FIcons.shield, size: 18, color: AppColors.violet),
            const SizedBox(height: 10),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: sportMutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: sportGlassDecoration(radius: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: sportMutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingChangeRow extends StatelessWidget {
  const _RatingChangeRow({
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
    final textTheme = Theme.of(context).textTheme;
    final color = _deltaColor(delta);
    final sign = delta > 0 ? '+' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: sportGlassDecoration(radius: 24),
      child: Row(
        children: [
          SportPlayerAvatar(
            initials: player.initials,
            imagePath: player.profileImagePath,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${initial?.round() ?? '-'} -> ${finalRating?.round() ?? '-'}',
                  style: textTheme.bodySmall?.copyWith(
                    color: sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.45)),
            ),
            child: Text(
              '$sign${delta.round()}',
              style: textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.violet),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.violet.withValues(alpha: 0.22)
            : AppColors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: emphasized
              ? AppColors.violet
              : AppColors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _deltaColor(double delta) {
  if (delta > 0) return AppColors.violet;
  if (delta < 0) return AppColors.danger;
  return sportMutedText;
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
