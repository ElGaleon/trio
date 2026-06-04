import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/widgets/app_empty_state.dart';

import '../app_router.dart';
import '../models/player.dart';
import '../models/scrimmage_match.dart';
import '../providers/elo_providers.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_trend_chart.dart';
import '../widgets/sport_style.dart';

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
      return const Scaffold(
        body: SportScreenShell(
          title: 'Player',
          subtitle: 'Profile not found',
          child: SportEmptyState(
            icon: Icons.person_off_outlined,
            title: 'Giocatore non trovato',
            message: 'Il profilo selezionato non e piu disponibile.',
          ),
        ),
      );
    }

    final currentPlayer = player;
    final matches = repository.matchesForPlayer(currentPlayer.id);
    final history = repository.ratingHistoryForPlayer(currentPlayer.id);
    final playersById = {
      for (final rankedPlayer in players) rankedPlayer.id: rankedPlayer,
    };

    return Scaffold(
      body: SportScreenShell(
        title: 'Player',
        subtitle: 'Performance profile',
        child: Column(
          children: [
            const SportBackButton(),
            const SizedBox(height: 14),
            _PlayerHero(player: currentPlayer),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: SportActionButton(
                label: 'Modifica',
                icon: FIcons.pencil,
                onPressed: () => context.push(
                  AppRoutes.editPlayer(currentPlayer.id),
                  extra: currentPlayer,
                ),
              ),
            ),
            const SizedBox(height: 14),
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
            const SizedBox(height: 20),
            const _SectionTitle(icon: FIcons.activity, title: 'Andamento ELO'),
            const SizedBox(height: 10),
            Container(
              decoration: sportGlassDecoration(),
              padding: const EdgeInsets.all(12),
              child: RatingTrendChart(values: history),
            ),
            const SizedBox(height: 20),
            const _SectionTitle(icon: FIcons.history, title: 'Partite giocate'),
            const SizedBox(height: 10),
            if (matches.isEmpty)
              const SportEmptyState(
                icon: FIcons.history,
                title: 'Nessuna partita',
                message: 'Questo giocatore non ha ancora partite registrate.',
              )
            else
              ...matches.map(
                (match) => _PlayerMatchRow(
                  player: currentPlayer,
                  match: match,
                  playersById: playersById,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlayerHero extends StatelessWidget {
  const _PlayerHero({required this.player});

  final Player player;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Hero(
      tag: 'player-${player.id}',
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SportPlayerAvatar(
                initials: player.initials,
                imagePath: player.profileImagePath,
                size: 76,
                featured: true,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      player.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _InfoPill(
                          icon: FIcons.sparkles,
                          label: '${player.rating.round()} ELO',
                          emphasized: true,
                        ),
                        _InfoPill(label: player.role.label),
                        _InfoPill(label: player.linePreference.label),
                        if (player.isExternal)
                          const _InfoPill(label: 'Esterno'),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.icon, this.emphasized = false});

  final String label;
  final IconData? icon;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: AppColors.white, size: 13),
            const SizedBox(width: 5),
          ],
          Text(
            label,
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
    final textTheme = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        decoration: sportGlassDecoration(radius: 22),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.violet),
            const SizedBox(height: 10),
            Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: sportMutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
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

class _PlayerMatchRow extends StatelessWidget {
  const _PlayerMatchRow({
    required this.player,
    required this.match,
    required this.playersById,
  });

  final Player player;
  final ScrimmageMatch match;
  final Map<String, Player> playersById;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isTeamA = match.teamAIds.contains(player.id);
    final resultLabel = match.isDraw
        ? 'Pareggio'
        : (isTeamA == match.teamAWon ? 'Vittoria' : 'Sconfitta');
    final delta = match.ratingDelta(player.id);
    final color = _deltaColor(delta);
    final sign = delta > 0 ? '+' : '';
    final teammates = (isTeamA ? match.teamAIds : match.teamBIds)
        .where((id) => id != player.id)
        .map((id) => playersById[id]?.name)
        .whereType<String>()
        .join(', ');
    final teamName = isTeamA ? match.teamAName : match.teamBName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: sportGlassDecoration(radius: 24),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.50)),
            ),
            child: Icon(_resultIcon(match, isTeamA, delta), color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$teamName · ${match.scoreA} - ${match.scoreB}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$resultLabel · ${teammates.isEmpty ? 'Nessun compagno' : teammates}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: sportMutedText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
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

IconData _resultIcon(ScrimmageMatch match, bool isTeamA, double delta) {
  if (match.isDraw || delta == 0) return FIcons.minus;
  return isTeamA == match.teamAWon ? FIcons.trendingUp : FIcons.trendingDown;
}

Color _deltaColor(double delta) {
  if (delta > 0) return AppColors.violet;
  if (delta < 0) return AppColors.danger;
  return sportMutedText;
}
