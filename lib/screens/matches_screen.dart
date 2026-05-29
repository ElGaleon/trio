import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../app_constants.dart';
import '../providers/elo_providers.dart';
import '../widgets/empty_state.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';
import 'match_form_screen.dart';

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

    return FScaffold(
      child: matches.isEmpty
          ? EmptyState(
              icon: Icons.scoreboard_outlined,
              title: 'Nessuna partitella',
              message: canCreate
                  ? 'Inserisci il risultato della prima partitella.'
                  : 'Servono almeno sei giocatori per un 3vs3.',
              action: FButton(
                onPress: () => _openMatchForm(context, canCreate),
                child: const Text('Crea partita'),
              ),
            )
          : ListView.separated(
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _MatchToolbar(
                    canCreate: canCreate,
                    onAdd: () => _openMatchForm(context, canCreate),
                    child: _MatchDateFilters(
                      startDate: startDate,
                      endDate: endDate,
                      onStartChanged: (value) =>
                          ref
                                  .read(matchesStartDateFilterProvider.notifier)
                                  .state =
                              value,
                      onEndChanged: (value) =>
                          ref
                                  .read(matchesEndDateFilterProvider.notifier)
                                  .state =
                              value,
                      onClear: () {
                        ref
                                .read(matchesStartDateFilterProvider.notifier)
                                .state =
                            null;
                        ref.read(matchesEndDateFilterProvider.notifier).state =
                            null;
                      },
                    ),
                  );
                }

                final match = filteredMatches[index - 1];
                return MatchCard(
                  match: match,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(matchId: match.id),
                    ),
                  ),
                  onEdit: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MatchFormScreen(match: match),
                    ),
                  ),
                  onDelete: () => repository.deleteMatch(match.id),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemCount: filteredMatches.length + 1,
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MatchFormScreen()),
    );
  }
}

class _MatchToolbar extends StatelessWidget {
  const _MatchToolbar({
    required this.canCreate,
    required this.onAdd,
    required this.child,
  });

  final bool canCreate;
  final VoidCallback onAdd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FCard(
      title: Row(
        children: [
          const Icon(FIcons.calendarDays, size: 18),
          const SizedBox(width: 8),
          const Expanded(child: Text('Partite')),
          FButton(
            size: .sm,
            onPress: onAdd,
            prefix: const Icon(FIcons.calendarPlus, size: 16),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
      subtitle: canCreate
          ? const Text('Filtra lo storico o registra una nuova partita.')
          : const Text('Servono almeno 6 giocatori per iniziare.'),
      child: child,
    );
  }
}

class _MatchDateFilters extends StatelessWidget {
  const _MatchDateFilters({
    required this.startDate,
    required this.endDate,
    required this.onStartChanged,
    required this.onEndChanged,
    required this.onClear,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateTime?> onStartChanged;
  final ValueChanged<DateTime?> onEndChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        Row(
          children: [
            Expanded(
              child: _DateButton(
                label: 'Inizio',
                date: startDate,
                onPressed: () async {
                  final selected = await _pickDate(context, startDate);
                  onStartChanged(selected);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DateButton(
                label: 'Fine',
                date: endDate,
                onPressed: () async {
                  final selected = await _pickDate(context, endDate);
                  onEndChanged(selected);
                },
              ),
            ),
          ],
        ),
        if (startDate != null || endDate != null)
          FButton(
            variant: .outline,
            onPress: onClear,
            prefix: const Icon(FIcons.calendarX, size: 16),
            child: const Text('Pulisci date'),
          ),
      ],
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

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.date,
    required this.onPressed,
  });

  final String label;
  final DateTime? date;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FButton(
      variant: .outline,
      onPress: onPressed,
      prefix: const Icon(FIcons.calendar, size: 16),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(date == null ? label : _dateLabel(date!)),
      ),
    );
  }
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}
