import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:trio/widgets/app_empty_state.dart';

import '../app_constants.dart';
import '../app_router.dart';
import '../providers/elo_providers.dart';
import '../widgets/match_card.dart';
import '../widgets/sport_style.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(eloRepositoryProvider);
    final matches = ref.watch(matchesProvider);
    final filteredMatches = ref.watch(filteredMatchesProvider);
    final startDate = ref.watch(matchesStartDateFilterProvider);
    final endDate = ref.watch(matchesEndDateFilterProvider);
    final players = ref.watch(rankedPlayersProvider);
    final canCreate = players.length >= AppConstants.minTeamSize * 2;
    final hasFilters = startDate != null || endDate != null;

    return SportScreenShell(
      title: 'Matches',
      subtitle: 'Track every scrimmage',
      floatingActionButton: SportFloatingActionButton(
        label: 'Nuova',
        onPressed: () => _openMatchForm(context, canCreate),
      ),
      child: matches.isEmpty
          ? SportEmptyState(
              icon: Icons.scoreboard_outlined,
              title: 'Nessuna partitella',
              message: canCreate
                  ? 'Inserisci il risultato della prima partitella.'
                  : 'Servono almeno sei giocatori per un 3vs3.',
            )
          : SafeArea(
              bottom: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                spacing: 8,
                children: [
                  _MatchToolbar(
                    totalCount: matches.length,
                    filteredCount: filteredMatches.length,
                    hasFilters: hasFilters,
                    canCreate: canCreate,
                  ),
                  _MatchDateFilters(
                    startDate: startDate,
                    endDate: endDate,
                    onStartChanged: (value) =>
                        ref
                                .read(matchesStartDateFilterProvider.notifier)
                                .state =
                            value,
                    onEndChanged: (value) =>
                        ref.read(matchesEndDateFilterProvider.notifier).state =
                            value,
                  ),
                  const SizedBox(height: 14),
                  if (filteredMatches.isEmpty)
                    const SportEmptyState(
                      icon: Icons.event_busy_outlined,
                      title: 'Nessuna partita',
                      message: 'Non ci sono partite nel periodo selezionato.',
                    )
                  else
                    ...filteredMatches.map((match) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: MatchCard(
                          match: match,
                          onTap: () =>
                              context.push(AppRoutes.matchDetail(match.id)),
                          onEdit: () => context.push(
                            AppRoutes.editMatch(match.id),
                            extra: match,
                          ),
                          onDelete: () => repository.deleteMatch(match.id),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  void _openMatchForm(BuildContext context, bool canCreate) {
    if (!canCreate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Servono almeno 6 giocatori per creare un 3vs3.'),
        ),
      );
      return;
    }
    context.push(AppRoutes.newMatch);
  }
}

class _MatchToolbar extends StatelessWidget {
  const _MatchToolbar({
    required this.totalCount,
    required this.filteredCount,
    required this.hasFilters,
    required this.canCreate,
  });

  final int totalCount;
  final int filteredCount;
  final bool hasFilters;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Text(
            canCreate
                ? hasFilters
                      ? '$filteredCount di $totalCount partite'
                      : '$totalCount partite'
                : 'Servono almeno 6 giocatori',
            style: textTheme.bodySmall?.copyWith(
              color: sportMutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchDateFilters extends StatelessWidget {
  const _MatchDateFilters({
    required this.startDate,
    required this.endDate,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        children: [
          SportFilterPill(
            icon: FIcons.calendar,
            label: startDate == null ? 'Da' : 'Da ${_dateLabel(startDate!)}',
            selected: startDate != null,
            onPressed: () async {
              final selected = await _pickDate(context, startDate);
              onStartChanged(selected);
            },
          ),
          const SizedBox(width: 8),
          SportFilterPill(
            icon: FIcons.calendar,
            label: endDate == null ? 'A' : 'A ${_dateLabel(endDate!)}',
            selected: endDate != null,
            onPressed: () async {
              final selected = await _pickDate(context, endDate);
              onEndChanged(selected);
            },
          ),
        ],
      ),
    );
  }

  Future<DateTime?> _pickDate(BuildContext context, DateTime? initial) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
    );
  }
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
