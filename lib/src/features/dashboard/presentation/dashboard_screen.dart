import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import 'package:skrim/src/features/matches/application/matches_providers.dart';
import 'package:skrim/src/features/matches/domain/scrimmage_match.dart';
import 'package:skrim/src/features/players/application/player_providers.dart';
import 'package:skrim/src/features/players/application/player_stats_provider.dart';
import 'package:skrim/src/features/players/domain/player.dart';
import 'package:skrim/src/features/players/domain/player_analytics.dart';
import 'package:skrim/src/features/players/domain/player_stats_card_data.dart';
import 'package:skrim/src/routing/app_router.dart';
import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/responsive_layout.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/shared/sport_player_avatar.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/theme/app_colors.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(rankedPlayersProvider);
    final matches = ref.watch(matchesProvider);
    final analytics = ref.watch(playerAnalyticsProvider);
    final now = DateTime.now();
    final finished = matches.where((match) => match.isFinished).length;
    final live = matches.where((match) => match.isLiveAt(now)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final upcoming =
        matches.where((match) => match.createdAt.isAfter(now)).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final recent =
        matches.where((match) => !match.createdAt.isAfter(now)).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final topRating = players.take(5).toList(growable: false);
    final topImpact = [...analytics.cards]
      ..sort((a, b) => b.impactScore.compareTo(a.impactScore));
    final topGoals = [...analytics.cards]
      ..sort((a, b) => b.goals.compareTo(a.goals));

    return SportScreenShell(
      title: 'Dashboard',
      subtitle: 'Panoramica squadra',
      child: players.isEmpty && matches.isEmpty
          ? const SportEmptyState(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard vuota',
              message:
                  'Aggiungi giocatori e partite per vedere le statistiche.',
            )
          : Column(
              spacing: 12,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveGrid(
                  minTileWidth: 210,
                  children: [
                    _MetricCard(
                      icon: FIcons.users,
                      label: 'Giocatori',
                      value: '${players.length}',
                      detail: '${_activePlayers(players)} attivi',
                      onTap: () => context.go(AppRoutes.players),
                    ),
                    _MetricCard(
                      icon: Icons.scoreboard_outlined,
                      label: 'Partite',
                      value: '${matches.length}',
                      detail: '$finished concluse',
                      onTap: () => context.go(AppRoutes.matches),
                    ),
                    _MetricCard(
                      icon: Icons.event_available_outlined,
                      label: 'Prossime',
                      value: '${upcoming.length}',
                      detail: upcoming.isEmpty
                          ? 'Nessuna in calendario'
                          : _dateLabel(upcoming.first.createdAt),
                      onTap: () => context.go(AppRoutes.matches),
                    ),
                    _MetricCard(
                      icon: FIcons.activity,
                      label: 'Win rate',
                      value: _percent(analytics.group.averageWinRate),
                      detail:
                          'ELO medio ${analytics.group.averageRating.round()}',
                      onTap: () => context.go(AppRoutes.stats),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop =
                        constraints.maxWidth >= ResponsiveLayout.desktop;
                    final left = Column(
                      spacing: 12,
                      children: [
                        _SchedulePanel(
                          title: live.isEmpty ? 'Prossime partite' : 'Live ora',
                          matches: live.isEmpty
                              ? upcoming.take(4).toList()
                              : live,
                          empty: live.isEmpty
                              ? 'Nessuna partita programmata.'
                              : 'Nessuna partita live.',
                        ),
                        _SchedulePanel(
                          title: 'Ultime partite',
                          matches: recent.take(4).toList(),
                          empty: 'Nessuna partita registrata.',
                        ),
                      ],
                    );
                    final right = Column(
                      spacing: 12,
                      children: [
                        _PlayersPanel(
                          title: 'Top players',
                          players: topRating,
                          trailing: (player) =>
                              player.rating.round().toString(),
                        ),
                        _StatsPanel(
                          cards: topImpact.take(5).toList(),
                          title: 'Classifica +/-',
                          value: (data) => _signed(data.impactScore),
                        ),
                        _StatsPanel(
                          cards: topGoals.take(5).toList(),
                          title: 'Mete',
                          value: (data) => '${data.goals}',
                        ),
                      ],
                    );
                    if (!desktop) {
                      return Column(spacing: 12, children: [left, right]);
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Expanded(flex: 3, child: left),
                        Expanded(flex: 2, child: right),
                      ],
                    );
                  },
                ),
                _AggregatePanel(analytics: analytics),
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
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: GlassDecoration(
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                Icon(icon, size: 18, color: AppColors.violetLight),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.sportForeground(context),
                  ),
                ),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.sportMutedForeground(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SchedulePanel extends StatelessWidget {
  const _SchedulePanel({
    required this.title,
    required this.matches,
    required this.empty,
  });

  final String title;
  final List<ScrimmageMatch> matches;
  final String empty;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      icon: Icons.calendar_month_outlined,
      child: matches.isEmpty
          ? _EmptyLine(text: empty)
          : Column(
              spacing: 8,
              children: [
                for (final match in matches)
                  _MatchLine(
                    match: match,
                    onTap: () => context.go(AppRoutes.matchDetail(match.id)),
                  ),
              ],
            ),
    );
  }
}

class _PlayersPanel extends StatelessWidget {
  const _PlayersPanel({
    required this.title,
    required this.players,
    required this.trailing,
  });

  final String title;
  final List<Player> players;
  final String Function(Player player) trailing;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      icon: FIcons.trophy,
      child: players.isEmpty
          ? const _EmptyLine(text: 'Nessun giocatore.')
          : Column(
              spacing: 8,
              children: [
                for (final entry in players.indexed)
                  _PlayerLine(
                    rank: entry.$1 + 1,
                    player: entry.$2,
                    trailing: trailing(entry.$2),
                  ),
              ],
            ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.cards,
    required this.title,
    required this.value,
  });

  final List<PlayerStatsCardData> cards;
  final String title;
  final String Function(PlayerStatsCardData data) value;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: title,
      icon: FIcons.chartNoAxesCombined,
      child: cards.isEmpty
          ? const _EmptyLine(text: 'Nessuna statistica.')
          : Column(
              spacing: 8,
              children: [
                for (final entry in cards.indexed)
                  _PlayerLine(
                    rank: entry.$1 + 1,
                    player: entry.$2.player,
                    trailing: value(entry.$2),
                  ),
              ],
            ),
    );
  }
}

class _AggregatePanel extends StatelessWidget {
  const _AggregatePanel({required this.analytics});

  final PlayerAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final group = analytics.group;
    return _Panel(
      title: 'Statistiche aggregate',
      icon: FIcons.activity,
      child: ResponsiveGrid(
        minTileWidth: 160,
        children: [
          _MiniMetric(label: 'Mete', value: '${group.goals}'),
          _MiniMetric(label: 'Assist', value: '${group.assists}'),
          _MiniMetric(label: 'Difese', value: '${group.defenses}'),
          _MiniMetric(label: 'Errori', value: '${group.errors}'),
          _MiniMetric(label: 'Pull', value: '${group.pulls}'),
          _MiniMetric(label: 'Pull in', value: _percent(group.pullInRate)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassDecoration(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                Icon(icon, size: 16, color: AppColors.violetLight),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.sportForeground(context),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _MatchLine extends StatelessWidget {
  const _MatchLine({required this.match, required this.onTap});

  final ScrimmageMatch match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: onTap,
        title: Text(
          '${match.teamAName} ${match.scoreA}-${match.scoreB} ${match.teamBName}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          [
            _dateLabel(match.createdAt),
            if (match.location.trim().isNotEmpty) match.location.trim(),
            if (match.tournament.trim().isNotEmpty) match.tournament.trim(),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.sportMutedForeground(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.sportMutedForeground(context),
        ),
      ),
    );
  }
}

class _PlayerLine extends StatelessWidget {
  const _PlayerLine({
    required this.rank,
    required this.player,
    required this.trailing,
  });

  final int rank;
  final Player player;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onTap: () => context.go(AppRoutes.playerDetail(player.id)),
        leading: SportPlayerAvatar(
          initials: player.initials,
          imagePath: player.profileImagePath,
          size: 32,
        ),
        title: Text(
          '$rank. ${player.name}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          '${player.role.label} · ${player.linePreference?.label ?? 'Nessuna'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.sportMutedForeground(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: Text(
          trailing,
          style: TextStyle(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.sportForeground(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.sportForeground(context).withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.sportForeground(context),
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
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
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.sportMutedForeground(context),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

int _activePlayers(List<Player> players) {
  return players.where((player) => player.matchesPlayed > 0).length;
}

String _percent(double value) => '${(value * 100).round()}%';

String _signed(double value) {
  final rounded = value.round();
  return rounded > 0 ? '+$rounded' : '$rounded';
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month $hour:$minute';
}
