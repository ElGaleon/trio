import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import 'package:skrim/src/shared/app_empty_state.dart';
import 'package:skrim/src/shared/sport_avatar_pill.dart';
import 'package:skrim/src/shared/responsive_layout.dart';
import 'package:skrim/src/shared/sport_screen_shell.dart';
import 'package:skrim/src/features/players/domain/player_line_preference.dart';
import 'package:skrim/src/features/players/domain/player_role.dart';
import 'package:skrim/src/features/players/application/player_stats_provider.dart';
import 'package:skrim/src/features/matches/presentation/matches/match_date_filters.dart';
import 'package:skrim/theme/app_colors.dart';
import 'package:skrim/src/shared/sport_glass_decoration_helper.dart';
import 'package:skrim/src/features/players/domain/group_stats.dart';
import 'package:skrim/src/features/players/domain/player_stats_card_data.dart';

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
        spacing: 10,
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
            if (ResponsiveLayout.isDesktop(context))
              _StatsTable(
                cards: analytics.cards,
                onSelect: (data) => ref
                    .read(selectedStatsPlayerIdProvider.notifier)
                    .set(data.player.id),
              )
            else
              _TopPlayersPanel(cards: analytics.cards),
            if (selected != null) _IndividualStatsPanel(data: selected),
          ],
        ],
      ),
    );
  }
}

class _StatsTable extends StatefulWidget {
  const _StatsTable({required this.cards, required this.onSelect});

  final List<PlayerStatsCardData> cards;
  final ValueChanged<PlayerStatsCardData> onSelect;

  @override
  State<_StatsTable> createState() => _StatsTableState();
}

class _StatsTableState extends State<_StatsTable> {
  var _sortColumnIndex = 1;
  var _sortAscending = false;

  @override
  Widget build(BuildContext context) {
    final rows = [...widget.cards];
    rows.sort((a, b) {
      final result = switch (_sortColumnIndex) {
        0 => a.player.name.toLowerCase().compareTo(b.player.name.toLowerCase()),
        2 => a.goals.compareTo(b.goals),
        3 => a.assists.compareTo(b.assists),
        4 => a.defenses.compareTo(b.defenses),
        5 => a.errors.compareTo(b.errors),
        6 => a.touches.compareTo(b.touches),
        7 => a.touchesPerPoint.compareTo(b.touchesPerPoint),
        8 => a.goalsPerPoint.compareTo(b.goalsPerPoint),
        9 => a.assistsPerPoint.compareTo(b.assistsPerPoint),
        10 => a.winRate.compareTo(b.winRate),
        _ => a.plusMinus.compareTo(b.plusMinus),
      };
      return _sortAscending ? result : -result;
    });

    return _TableShell(
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        headingRowHeight: 38,
        dataRowMinHeight: 42,
        dataRowMaxHeight: 48,
        columns: [
          _column('Giocatore', 0),
          _column('+/-', 1),
          _column('Mete', 2),
          _column('Assist', 3),
          _column('Difese', 4),
          _column('Errori', 5),
          _column('Tocchi', 6),
          _column('Tocchi/PT', 7),
          _column('Mete/PT', 8),
          _column('Assist/PT', 9),
          _column('Win', 10),
        ],
        rows: [
          for (final data in rows)
            DataRow(
              cells: [
                DataCell(
                  Text(data.player.name),
                  onTap: () => widget.onSelect(data),
                ),
                DataCell(Text(_signed(data.plusMinus))),
                DataCell(Text('${data.goals}')),
                DataCell(Text('${data.assists}')),
                DataCell(Text('${data.defenses}')),
                DataCell(Text('${data.errors}')),
                DataCell(Text('${data.touches}')),
                DataCell(Text(_percent(data.touchesPerPoint))),
                DataCell(Text(_percent(data.goalsPerPoint))),
                DataCell(Text(_percent(data.assistsPerPoint))),
                DataCell(Text(_percent(data.winRate))),
              ],
            ),
        ],
      ),
    );
  }

  DataColumn _column(String label, int index) {
    return DataColumn(
      label: Text(label),
      onSort: (columnIndex, ascending) {
        setState(() {
          _sortColumnIndex = columnIndex;
          _sortAscending = ascending;
        });
      },
    );
  }
}

class _StatsFilters extends ConsumerWidget {
  const _StatsFilters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(statsRoleFilterProvider);
    final line = ref.watch(statsLineFilterProvider);
    final startDate = ref.watch(statsStartDateFilterProvider);
    final endDate = ref.watch(statsEndDateFilterProvider);

    return Column(
      spacing: 6,
      children: [
        MatchDateFilters(
          startDate: startDate,
          endDate: endDate,
          onStartChanged: (value) =>
              ref.read(statsStartDateFilterProvider.notifier).set(value),
          onEndChanged: (value) =>
              ref.read(statsEndDateFilterProvider.notifier).set(value),
        ),
        Material(
          color: AppColors.transparent,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.sportForeground(context).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.sportForeground(
                  context,
                ).withValues(alpha: 0.12),
              ),
            ),
            child: TextField(
              onChanged: (value) =>
                  ref.read(statsSearchQueryProvider.notifier).set(value),
              style: TextStyle(
                color: AppColors.sportForeground(context),
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
                  horizontal: 12,
                  vertical: 10,
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
                    ref.read(statsRoleFilterProvider.notifier).set(null),
              ),
              for (final value in PlayerRole.values)
                SportFilterPill(
                  label: value.label,
                  selected: role == value,
                  onPressed: () =>
                      ref.read(statsRoleFilterProvider.notifier).set(value),
                ),
              const SizedBox(width: 4),
              SportFilterPill(
                label: 'Tutte linee',
                selected: line == null,
                onPressed: () =>
                    ref.read(statsLineFilterProvider.notifier).set(null),
              ),
              for (final value in PlayerLinePreference.values)
                SportFilterPill(
                  label: value.label,
                  selected: line == value,
                  onPressed: () =>
                      ref.read(statsLineFilterProvider.notifier).set(value),
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
    return GlassDecoration(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(icon: FIcons.users, title: 'Statistiche gruppo'),
            _MetricStrip(
              items: [
                ('Giocatori', '${stats.playerCount}'),
                ('ELO', stats.averageRating.round().toString()),
                ('Win rate', _percent(stats.averageWinRate)),
                ('Mete', '${stats.goals}'),
              ],
            ),
            _MetricStrip(
              items: [
                ('Difese', '${stats.defenses}'),
                ('Errori', '${stats.errors}'),
                ('Pull', '${stats.pulls}'),
                ('Pull in', _percent(stats.pullInRate)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TopPlayersPanel extends ConsumerStatefulWidget {
  const _TopPlayersPanel({required this.cards});

  final List<PlayerStatsCardData> cards;

  @override
  ConsumerState<_TopPlayersPanel> createState() => _TopPlayersPanelState();
}

class _TopPlayersPanelState extends ConsumerState<_TopPlayersPanel> {
  static const _pageSize = 8;
  var _page = 0;

  @override
  Widget build(BuildContext context) {
    final sorted = [...widget.cards]
      ..sort((a, b) => b.impactScore.compareTo(a.impactScore));
    final maxPage = ((sorted.length - 1) / _pageSize).floor().clamp(0, 999);
    if (_page > maxPage) _page = maxPage;
    final visible = sorted.skip(_page * _pageSize).take(_pageSize);

    return GlassDecoration(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PanelTitle(
              icon: FIcons.chartNoAxesCombined,
              title: 'Classifica +/-',
            ),
            for (final data in visible)
              _PlayerAnalyticsRow(
                data: data,
                onTap: () => ref
                    .read(selectedStatsPlayerIdProvider.notifier)
                    .set(data.player.id),
              ),
            _PagerControls(
              page: _page,
              maxPage: maxPage,
              onPrevious: _page == 0 ? null : () => setState(() => _page--),
              onNext: _page == maxPage ? null : () => setState(() => _page++),
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
    return GlassDecoration(
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 10,
              children: [
                SportPlayerAvatar(
                  initials: data.player.initials,
                  imagePath: data.player.profileImagePath,
                  size: 42,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.player.name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.sportForeground(context),
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
            _MetricStrip(
              items: [
                ('Match', '${data.matchesPlayed}'),
                ('Win', _percent(data.winRate)),
                ('PT', '${data.pointsPlayed}'),
                ('+/-', _signed(data.plusMinus)),
              ],
            ),
            _MetricStrip(
              items: [
                ('Mete', '${data.goals}'),
                ('Assist', '${data.assists}'),
                ('Difese', '${data.defenses}'),
                ('Errori', '${data.errors}'),
              ],
            ),
            _MetricStrip(
              items: [
                ('Tocchi', '${data.touches}'),
                ('Tocchi/PT', _percent(data.touchesPerPoint)),
                ('Mete/PT', _percent(data.goalsPerPoint)),
                ('Assist/PT', _percent(data.assistsPerPoint)),
              ],
            ),
            _MetricStrip(
              items: [
                ('Pull in', _percent(data.pullInRate)),
                (
                  'Pull medio',
                  '${data.averagePullSeconds.toStringAsFixed(1)}s',
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
        Icon(icon, color: AppColors.violetLight, size: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.sportForeground(context),
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.items});

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
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.sportForeground(
                    context,
                  ).withValues(alpha: 0.08),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                        color: sportMutedText,
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

class _TableShell extends StatelessWidget {
  const _TableShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sportForeground(context).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.sportForeground(context).withValues(alpha: 0.10),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}

class _PagerControls extends StatelessWidget {
  const _PagerControls({
    required this.page,
    required this.maxPage,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int maxPage;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          IconButton(onPressed: onPrevious, icon: Icon(Icons.chevron_left)),
          Text(
            '${page + 1}/${maxPage + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.sportMutedForeground(context),
              fontWeight: FontWeight.w800,
            ),
          ),
          IconButton(onPressed: onNext, icon: Icon(Icons.chevron_right)),
        ],
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
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.sportForeground(context).withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.sportForeground(context).withValues(alpha: 0.07),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            spacing: 10,
            children: [
              SportPlayerAvatar(
                initials: data.player.initials,
                imagePath: data.player.profileImagePath,
                size: 32,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.player.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.sportForeground(context),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'M ${data.goals} · A ${data.assists} · D ${data.defenses} · T/PT ${_percent(data.touchesPerPoint)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          value.toString(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
