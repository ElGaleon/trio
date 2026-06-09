import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:trio/src/common_widgets/app_empty_state.dart';
import 'package:trio/src/common_widgets/sport_avatar_pill.dart';
import 'package:trio/src/common_widgets/sport_screen_shell.dart';
import 'package:trio/src/features/players/domain/player_line_preference.dart';
import 'package:trio/src/features/players/domain/player_role.dart';
import 'package:trio/src/features/players/application/player_stats_provider.dart';
import 'package:trio/src/theme/app_colors.dart';
import 'package:trio/src/common_widgets/sport_glass_decoration_helper.dart';
import 'package:trio/src/features/players/domain/group_stats.dart';
import 'package:trio/src/features/players/domain/player_stats_card_data.dart';

class PlayerStatsScreen extends ConsumerWidget {
  const PlayerStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(playerAnalyticsProvider);
    final selectedId = ref.watch(selectedStatsPlayerIdProvider);
    final selected = analytics.byId(selectedId);

    return SportScreenShell(
      title: 'Stats',
      subtitle: 'Group and individual analysis',
      child: Column(
        spacing: 14,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StatsFilters(),
          if (analytics.cards.isEmpty)
            const SportEmptyState(
              icon: FIcons.searchX,
              title: 'Nessun giocatore',
              message: 'Modifica i filtri per vedere le statistiche.',
            )
          else ...[
            _GroupStatsPanel(stats: analytics.group),
            _TopPlayersPanel(cards: analytics.cards),
            if (selected != null) _IndividualStatsPanel(data: selected),
          ],
        ],
      ),
    );
  }
}

class _StatsFilters extends ConsumerWidget {
  const _StatsFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(statsRoleFilterProvider);
    final line = ref.watch(statsLineFilterProvider);

    return Column(
      spacing: 10,
      children: [
        Material(
          color: AppColors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
              ),
            ),
            child: TextField(
              onChanged: (value) =>
                  ref.read(statsSearchQueryProvider.notifier).state = value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                hintText: 'Cerca giocatore',
                hintStyle: TextStyle(color: sportMutedText),
                prefixIcon: Icon(
                  FIcons.search,
                  color: sportMutedText,
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: 8,
            children: [
              SportFilterPill(
                label: 'Tutti ruoli',
                selected: role == null,
                onPressed: () =>
                    ref.read(statsRoleFilterProvider.notifier).state = null,
              ),
              for (final value in PlayerRole.values)
                SportFilterPill(
                  label: value.label,
                  selected: role == value,
                  onPressed: () =>
                      ref.read(statsRoleFilterProvider.notifier).state = value,
                ),
              const SizedBox(width: 4),
              SportFilterPill(
                label: 'Tutte linee',
                selected: line == null,
                onPressed: () =>
                    ref.read(statsLineFilterProvider.notifier).state = null,
              ),
              for (final value in PlayerLinePreference.values)
                SportFilterPill(
                  label: value.label,
                  selected: line == value,
                  onPressed: () =>
                      ref.read(statsLineFilterProvider.notifier).state = value,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupStatsPanel extends StatelessWidget {
  const _GroupStatsPanel({required this.stats});

  final GroupStats stats;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(icon: FIcons.users, title: 'Statistiche gruppo'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.62,
              children: [
                _MetricTile(label: 'Giocatori', value: '${stats.playerCount}'),
                _MetricTile(
                  label: 'ELO medio',
                  value: stats.averageRating.round().toString(),
                ),
                _MetricTile(
                  label: 'Win rate medio',
                  value: _percent(stats.averageWinRate),
                ),
                _MetricTile(label: 'Mete', value: '${stats.goals}'),
                _MetricTile(label: 'Difese', value: '${stats.defenses}'),
                _MetricTile(label: 'Errori', value: '${stats.errors}'),
                _MetricTile(label: 'Pull', value: '${stats.pulls}'),
                _MetricTile(
                  label: 'Pull dentro',
                  value: _percent(stats.pullInRate),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPlayersPanel extends ConsumerWidget {
  const _TopPlayersPanel({required this.cards});

  final List<PlayerStatsCardData> cards;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...cards]
      ..sort((a, b) => b.impactScore.compareTo(a.impactScore));

    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(
              icon: FIcons.chartNoAxesCombined,
              title: 'Classifica +/-',
            ),
            for (final data in sorted.take(8))
              _PlayerAnalyticsRow(
                data: data,
                onTap: () =>
                    ref.read(selectedStatsPlayerIdProvider.notifier).state =
                        data.player.id,
              ),
          ],
        ),
      ),
    );
  }
}

class _IndividualStatsPanel extends StatelessWidget {
  const _IndividualStatsPanel({required this.data});

  final PlayerStatsCardData data;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: sportGlassDecoration(radius: 28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: 14,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 12,
              children: [
                SportPlayerAvatar(
                  initials: data.player.initials,
                  imagePath: data.player.profileImagePath,
                  featured: true,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.player.name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${data.player.role.label} · ${data.player.linePreference?.label ?? 'Nessuna'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: sportMutedText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                _ImpactBadge(value: data.impactScore.round()),
              ],
            ),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.74,
              children: [
                _MetricTile(label: 'Match', value: '${data.matchesPlayed}'),
                _MetricTile(label: 'Win rate', value: _percent(data.winRate)),
                _MetricTile(label: 'Mete', value: '${data.goals}'),
                _MetricTile(label: 'Assist', value: '${data.assists}'),
                _MetricTile(label: 'Difese', value: '${data.defenses}'),
                _MetricTile(label: 'Errori', value: '${data.errors}'),
                _MetricTile(label: '+/- stats', value: _signed(data.plusMinus)),
                _MetricTile(label: 'Tocchi', value: '${data.touches}'),
                _MetricTile(
                  label: 'Pull medio',
                  value: '${data.averagePullSeconds.toStringAsFixed(1)}s',
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
            color: AppColors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.10)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: sportMutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerAnalyticsRow extends StatelessWidget {
  const _PlayerAnalyticsRow({required this.data, required this.onTap});

  final PlayerStatsCardData data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        spacing: 12,
        children: [
          SportPlayerAvatar(
            initials: data.player.initials,
            imagePath: data.player.profileImagePath,
            size: 40,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '+/- ${_signed(data.plusMinus)} · M ${data.goals} · D ${data.defenses}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: sportMutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          _ImpactBadge(value: data.impactScore.round()),
        ],
      ),
    );
  }
}

class _ImpactBadge extends StatelessWidget {
  const _ImpactBadge({required this.value});

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
            color: AppColors.white,
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
