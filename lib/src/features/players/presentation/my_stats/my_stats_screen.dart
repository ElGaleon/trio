import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/application/player_stats_provider.dart';
import 'package:skrim/src/features/players/domain/player_detail_stats.dart';
import 'package:skrim/src/features/players/domain/player_stats_card_data.dart';
import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/sport_avatar_pill.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/theme/app_colors.dart';

class MyStatsScreen extends ConsumerWidget {
  const MyStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(currentUserPlayerProvider);
    if (player == null) {
      return const SportScreenShell(
        title: 'Le mie stats',
        subtitle: 'Profilo personale',
        child: SportEmptyState(
          icon: Icons.account_circle_outlined,
          title: 'Nessun giocatore collegato',
          message:
              'Accetta un invito oppure chiedi al proprietario di collegare il tuo account a un giocatore.',
        ),
      );
    }

    final detail = ref.watch(playerDetailStatsProvider(player.id));
    if (detail == null) {
      return const SportScreenShell(
        title: 'Le mie stats',
        subtitle: 'Profilo personale',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SportScreenShell(
      title: 'Le mie stats',
      subtitle: 'Profilo personale',
      child: Column(
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MyProfileHeader(data: detail.data),
          _MyStatsFilters(playerId: player.id, detail: detail),
          _MyStatsGrid(data: detail.data),
          _MyMatchesPanel(matches: detail.matches),
        ],
      ),
    );
  }
}

class _MyProfileHeader extends StatelessWidget {
  const _MyProfileHeader({required this.data});

  final PlayerStatsCardData data;

  @override
  Widget build(BuildContext context) {
    final player = data.player;
    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          spacing: 14,
          children: [
            SportPlayerAvatar(
              initials: player.initials,
              imagePath: player.profileImagePath,
              size: 64,
              featured: true,
            ),
            Expanded(
              child: Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.sportForeground(context),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    [
                      player.fullName,
                      player.email,
                      player.role.label,
                    ].where((value) => value.trim().isNotEmpty).join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            _ScoreBadge(value: data.impactScore.round()),
          ],
        ),
      ),
    );
  }
}

class _MyStatsFilters extends ConsumerWidget {
  const _MyStatsFilters({required this.playerId, required this.detail});

  final String playerId;
  final PlayerDetailStats detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tournament = ref.watch(
      playerDetailTournamentFilterProvider(playerId),
    );
    final matchId = ref.watch(playerDetailMatchFilterProvider(playerId));
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              SportFilterPill(
                label: 'Tutti tornei',
                selected: tournament == null,
                onPressed: () {
                  ref
                      .read(
                        playerDetailTournamentFilterProvider(playerId).notifier,
                      )
                      .set(null);
                  ref
                      .read(playerDetailMatchFilterProvider(playerId).notifier)
                      .set(null);
                },
              ),
              for (final item in detail.tournaments)
                SportFilterPill(
                  label: item,
                  selected: tournament == item,
                  onPressed: () {
                    ref
                        .read(
                          playerDetailTournamentFilterProvider(
                            playerId,
                          ).notifier,
                        )
                        .set(item);
                    ref
                        .read(
                          playerDetailMatchFilterProvider(playerId).notifier,
                        )
                        .set(null);
                  },
                ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              SportFilterPill(
                label: 'Tutte partite',
                selected: matchId == null,
                onPressed: () => ref
                    .read(playerDetailMatchFilterProvider(playerId).notifier)
                    .set(null),
              ),
              for (final match in detail.matches)
                SportFilterPill(
                  label:
                      '${match.teamAName} ${match.scoreA}-${match.scoreB} ${match.teamBName}',
                  selected: matchId == match.id,
                  onPressed: () => ref
                      .read(playerDetailMatchFilterProvider(playerId).notifier)
                      .set(match.id),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyStatsGrid extends StatelessWidget {
  const _MyStatsGrid({required this.data});

  final PlayerStatsCardData data;

  @override
  Widget build(BuildContext context) {
    return GlassDecoration(
      radius: 22,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 6,
          children: [
            _CompactStatRow(
              items: [
                ('Match', '${data.matchesPlayed}'),
                ('Win rate', _percent(data.winRate)),
                ('+/-', _signed(data.plusMinus)),
              ],
            ),
            _CompactStatRow(
              items: [
                ('PT', '${data.pointsPlayed}'),
                ('Tocchi', '${data.touches}'),
                ('Difese', '${data.defenses}'),
              ],
            ),
            _CompactStatRow(
              items: [
                ('Tocchi/PT', _percent(data.touchesPerPoint)),
                ('Mete/PT', _percent(data.goalsPerPoint)),
                ('Assist/PT', _percent(data.assistsPerPoint)),
              ],
            ),
            _CompactStatRow(
              items: [
                ('Mete', '${data.goals}'),
                ('Assist', '${data.assists}'),
                ('Errori', '${data.errors}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MyMatchesPanel extends StatelessWidget {
  const _MyMatchesPanel({required this.matches});

  final List<ScrimmageMatch> matches;

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const SportEmptyState(
        icon: Icons.history,
        title: 'Nessuna partita',
        message: 'Non ci sono partite con i filtri correnti.',
      );
    }

    return GlassDecoration(
      radius: 28,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(icon: FIcons.history, title: 'Partite filtrate'),
            for (final match in matches)
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: Text(
                      '${match.teamAName} ${match.scoreA}-${match.scoreB} ${match.teamBName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    match.createdAt.toLocal().toString().split(' ').first,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.sportMutedForeground(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Icon(icon, color: AppColors.violetLight, size: 18),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CompactStatRow extends StatelessWidget {
  const _CompactStatRow({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [
        for (final item in items)
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.sportForeground(
                  context,
                ).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.sportForeground(
                    context,
                  ).withValues(alpha: 0.09),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      item.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.sportMutedForeground(context),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.violet.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.violet),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          value.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _percent(double value) => '${(value * 100).round()}%';

String _signed(double value) {
  final rounded = value.toStringAsFixed(
    value.truncateToDouble() == value ? 0 : 1,
  );
  return value > 0 ? '+$rounded' : rounded;
}
